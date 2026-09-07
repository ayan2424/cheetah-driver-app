<?php
/**
 * Cheetah Driver & Picker Mobile App - Update Status (Electronic Proof of Delivery)
 * 
 * Handles delivery status transitions, OTP verification, drop-off photo upload,
 * digital signature PNG processing, and automatic COD wallet settlement.
 */

require_once __DIR__ . '/../../../config.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed. Use POST.', 405);
}

$user = get_authenticated_user($conn, ['driver', 'picker']);
if (!$user) {
    json_error('Invalid or expired authentication token.', 401);
}

$driverId = (int)$user['id'];

// 1. Input Extraction
$trackingNumber = trim((string)($_POST['tracking_number'] ?? ''));
$parcelId = (int)($_POST['parcel_id'] ?? 0);
$newStatus = trim((string)($_POST['status'] ?? ''));
$receiverName = trim((string)($_POST['receiver_name'] ?? ''));
$description = trim((string)($_POST['description'] ?? 'Status updated by driver via Mobile App'));
$deliveryOtp = trim((string)($_POST['delivery_otp'] ?? ''));

$validStatuses = ['Pending', 'In Transit', 'Out for Delivery', 'Delivered', 'Returned', 'Failed Attempt'];

if (empty($trackingNumber) || empty($newStatus) || !in_array($newStatus, $validStatuses, true)) {
    json_error('A valid tracking number and recognized status are required.', 400);
}

// 2. Fetch Active Parcel & Verify Ownership
$sql = "SELECT id, tracking_number, driver_id, status, payment_status, amount, 
               delivery_otp_hash, delivery_otp_expires_at, delivery_otp_attempts,
               proof_of_delivery, signature_data
        FROM parcels 
        WHERE tracking_number = ? OR id = ? 
        LIMIT 1";

$stmt = $conn->prepare($sql);
$stmt->bind_param('si', $trackingNumber, $parcelId);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows === 0) {
    $stmt->close();
    json_error('Shipment record not found in system.', 404);
}

$parcel = $res->fetch_assoc();
$stmt->close();

$actualParcelId = (int)$parcel['id'];

// Driver ownership check
if (!empty($parcel['driver_id']) && (int)$parcel['driver_id'] !== $driverId && $user['role'] !== 'admin') {
    json_error('Access denied. This shipment is assigned to another delivery agent.', 403);
}

// Check terminal state
if (in_array($parcel['status'], ['Delivered', 'Returned'], true) && $newStatus !== $parcel['status']) {
    json_error("Shipment is already marked as {$parcel['status']}. Terminal statuses cannot be rolled back.", 400);
}

// 3. OTP Verification for High-Value / Cash Deliveries
if ($newStatus === 'Delivered' && !empty($parcel['delivery_otp_hash'])) {
    // Check expiry
    if (!empty($parcel['delivery_otp_expires_at']) && strtotime((string)$parcel['delivery_otp_expires_at']) < time()) {
        json_error('Delivery OTP has expired. Please ask the recipient to request a new code.', 400);
    }

    if (empty($deliveryOtp)) {
        json_error('Delivery OTP is mandatory for this shipment.', 400);
    }

    // Verify OTP using sha256 or password_verify
    $submittedHash = hash('sha256', $deliveryOtp);
    $isValidOtp = hash_equals($parcel['delivery_otp_hash'], $submittedHash) || password_verify($deliveryOtp, $parcel['delivery_otp_hash']);

    if (!$isValidOtp) {
        $conn->query("UPDATE parcels SET delivery_otp_attempts = delivery_otp_attempts + 1 WHERE id = {$actualParcelId}");
        json_error('Invalid delivery OTP code entered. Please re-check with consignee.', 400);
    }
}

// 4. Handle POD Drop-Off Photo Upload
$podPhotoPath = $parcel['proof_of_delivery'];
if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
    $fileTmp = $_FILES['photo']['tmp_name'];
    $fileName = $_FILES['photo']['name'];
    $fileSize = $_FILES['photo']['size'];

    $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
    $allowedExts = ['jpg', 'jpeg', 'png', 'webp'];

    if (in_array($ext, $allowedExts, true) && $fileSize <= 10 * 1024 * 1024) {
        $safeName = 'pod_' . date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
        $destPath = __DIR__ . '/../../../uploads/pod/' . $safeName;
        if (move_uploaded_file($fileTmp, $destPath)) {
            $podPhotoPath = 'uploads/pod/' . $safeName;
        }
    }
}

// 5. Handle Digital Signature Capture Upload
$signaturePath = $parcel['signature_data'];
if (isset($_FILES['signature']) && $_FILES['signature']['error'] === UPLOAD_ERR_OK) {
    $sigTmp = $_FILES['signature']['tmp_name'];
    $sigName = $_FILES['signature']['name'];

    $sigExt = strtolower(pathinfo($sigName, PATHINFO_EXTENSION));
    if (in_array($sigExt, ['png', 'jpg', 'jpeg', 'webp'], true)) {
        $safeSigName = 'sig_' . date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.png';
        $destSigPath = __DIR__ . '/../../../uploads/signatures/' . $safeSigName;
        if (move_uploaded_file($sigTmp, $destSigPath)) {
            $signaturePath = 'uploads/signatures/' . $safeSigName;
        }
    }
}

// 6. Update Shipment Record
$updateSql = "UPDATE parcels SET 
                status = ?, 
                proof_of_delivery = ?, 
                signature_data = ?,
                driver_id = ?,
                receiver_name = CASE WHEN ? != '' THEN ? ELSE receiver_name END,
                cod_collected = CASE WHEN ? = 'Delivered' AND payment_status = 'COD' THEN 1 ELSE cod_collected END,
                updated_at = NOW()
              WHERE id = ?";

$upStmt = $conn->prepare($updateSql);
$upStmt->bind_param('ssissssi', $newStatus, $podPhotoPath, $signaturePath, $driverId, $receiverName, $receiverName, $newStatus, $actualParcelId);
$upStmt->execute();
$upStmt->close();

// 7. Audit Trail in parcel_history
$histStmt = $conn->prepare("INSERT INTO parcel_history (parcel_id, status, location, notes, updated_by) VALUES (?, ?, ?, ?, ?)");
if ($histStmt) {
    $loc = 'On Field Route';
    $histStmt->bind_param('isssi', $actualParcelId, $newStatus, $loc, $description, $driverId);
    $histStmt->execute();
    $histStmt->close();
}

// 8. Financial Reconciliation on Delivery
if ($newStatus === 'Delivered') {
    // 8a. Credit Driver Commission ($5.00 default)
    $commissionAmount = 5.00;
    $commStmt = $conn->prepare("INSERT INTO driver_commissions (driver_id, parcel_id, amount, status, created_at) 
                                VALUES (?, ?, ?, 'pending', NOW())");
    if ($commStmt) {
        $commStmt->bind_param('iid', $driverId, $actualParcelId, $commissionAmount);
        $commStmt->execute();
        $commStmt->close();
    }

    // 8b. Update Driver Wallet
    $codCollected = ($parcel['payment_status'] === 'COD') ? (float)$parcel['amount'] : 0.00;
    $walletStmt = $conn->prepare("INSERT INTO driver_wallets (driver_id, balance, pending_cod, total_withdrawn, created_at)
                                  VALUES (?, ?, ?, 0.00, NOW())
                                  ON DUPLICATE KEY UPDATE 
                                      balance = balance + ?, 
                                      pending_cod = pending_cod + ?");
    if ($walletStmt) {
        $walletStmt->bind_param('idddd', $driverId, $commissionAmount, $codCollected, $commissionAmount, $codCollected);
        $walletStmt->execute();
        $walletStmt->close();
    }

    // 8c. Log Wallet Transaction
    $txStmt = $conn->prepare("INSERT INTO driver_wallet_transactions (wallet_id, driver_id, parcel_id, type, amount, balance_after, description, idempotency_key)
                              SELECT w.id, ?, ?, 'commission', ?, w.balance, ?, ?
                              FROM driver_wallets w WHERE w.driver_id = ? LIMIT 1");
    if ($txStmt) {
        $desc = "Commission for delivering {$parcel['tracking_number']}";
        $idempotency = "POD_{$actualParcelId}_" . time();
        $txStmt->bind_param('iidssi', $driverId, $actualParcelId, $commissionAmount, $desc, $idempotency, $driverId);
        $txStmt->execute();
        $txStmt->close();
    }
}

// 9. Format Response
$photoUrl = $podPhotoPath ? (str_starts_with($podPhotoPath, 'http') ? $podPhotoPath : BASE_URL . ltrim($podPhotoPath, '/')) : null;
$sigUrl = $signaturePath ? (str_starts_with($signaturePath, 'http') ? $signaturePath : BASE_URL . ltrim($signaturePath, '/')) : null;

json_response([
    'success' => true,
    'message' => "Shipment status successfully updated to {$newStatus}.",
    'status' => $newStatus,
    'tracking_number' => $parcel['tracking_number'],
    'proof_of_delivery' => $photoUrl,
    'signature_data' => $sigUrl
]);
