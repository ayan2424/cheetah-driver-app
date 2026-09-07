<?php
/**
 * Cheetah Driver & Picker Mobile App - Get Assigned Parcels Endpoint
 * 
 * Returns shipments assigned to the authenticated driver with real-time KPI metrics.
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

// Aggregate statistics
$stats = [
    'out_for_delivery' => 0,
    'in_transit' => 0,
    'delivered_today' => 0,
    'cod_total' => 0.00
];

// Query parcels assigned to this driver
$sql = "SELECT p.id, p.tracking_number, p.driver_id, p.origin_branch_id, p.destination_branch_id,
               p.sender_name, p.sender_phone, p.sender_address,
               p.receiver_name, p.receiver_phone, p.receiver_address,
               p.weight, p.status, p.payment_status, p.amount,
               p.cod_collected, p.cod_settled,
               p.delivery_otp_hash, p.delivery_otp_expires_at,
               p.created_at, p.updated_at,
               b.name AS origin_branch_name
        FROM parcels p
        LEFT JOIN branches b ON p.origin_branch_id = b.id
        WHERE p.driver_id = ?
        ORDER BY 
            CASE 
                WHEN p.status = 'Out for Delivery' THEN 1 
                WHEN p.status = 'Pending' THEN 2 
                WHEN p.status = 'In Transit' THEN 3 
                ELSE 4 
            END,
            p.id DESC
        LIMIT 100";

$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $driverId);
$stmt->execute();
$result = $stmt->get_result();

$parcels = [];
$todayDate = date('Y-m-d');

while ($row = $result->fetch_assoc()) {
    // Check if OTP is actively required for this parcel
    $requiresOtp = false;
    if ($row['status'] === 'Out for Delivery' && !empty($row['delivery_otp_hash'])) {
        if (!empty($row['delivery_otp_expires_at'])) {
            $requiresOtp = (strtotime((string)$row['delivery_otp_expires_at']) > time());
        } else {
            $requiresOtp = true;
        }
    }

    $row['requires_otp'] = $requiresOtp;
    unset($row['delivery_otp_hash'], $row['delivery_otp_expires_at']);

    // Ensure origin branch name is clean
    $row['origin_branch_name'] = $row['origin_branch_name'] ?? 'Main Logistics Hub';

    $parcels[] = $row;

    // Calculate metrics
    if ($row['status'] === 'Out for Delivery') {
        $stats['out_for_delivery']++;
    } elseif ($row['status'] === 'In Transit') {
        $stats['in_transit']++;
    } elseif ($row['status'] === 'Delivered' && date('Y-m-d', strtotime($row['updated_at'])) === $todayDate) {
        $stats['delivered_today']++;
    }

    if ($row['payment_status'] === 'COD' && $row['status'] === 'Delivered' && (int)$row['cod_settled'] === 0) {
        $stats['cod_total'] += (float)$row['amount'];
    }
}
$stmt->close();

json_response([
    'success' => true,
    'parcels' => $parcels,
    'stats' => $stats
]);
