<?php
/**
 * Cheetah Driver & Picker Mobile App - Get Profile Endpoint
 * 
 * Returns full profile details, assigned hub/branch info, and operational stats.
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

$userId = (int)$user['id'];
$branchId = (int)$user['branch_id'];

// 1. Fetch Branch Information
$branchStmt = $conn->prepare("SELECT id, name, code, city, address FROM branches WHERE id = ? LIMIT 1");
$branchStmt->bind_param('i', $branchId);
$branchStmt->execute();
$branchRes = $branchStmt->get_result()->fetch_assoc();
$branchStmt->close();

$branchData = [
    'id' => $branchId,
    'name' => htmlspecialchars($branchRes['name'] ?? 'Main Logistics Hub', ENT_QUOTES, 'UTF-8'),
    'code' => htmlspecialchars($branchRes['code'] ?? 'HUB-01', ENT_QUOTES, 'UTF-8'),
    'city' => htmlspecialchars($branchRes['city'] ?? 'Karachi', ENT_QUOTES, 'UTF-8'),
    'address' => htmlspecialchars($branchRes['address'] ?? '', ENT_QUOTES, 'UTF-8')
];

// 2. Format Profile Image URL
$avatarUrl = null;
if (!empty($user['profile_image'])) {
    $avatarUrl = str_starts_with($user['profile_image'], 'http')
        ? $user['profile_image']
        : BASE_URL . ltrim($user['profile_image'], '/');
} else {
    $avatarUrl = "https://ui-avatars.com/api/?name=" . urlencode($user['name']) . "&background=FF4D00&color=fff&size=200";
}

// 3. Operational Statistics for Driver
$totalAssigned = 0;
$deliveredToday = 0;
$pendingCod = 0.00;
$todayDate = date('Y-m-d');

$pStmt = $conn->prepare("SELECT status, payment_status, amount, updated_at FROM parcels WHERE driver_id = ?");
$pStmt->bind_param('i', $userId);
$pStmt->execute();
$pRes = $pStmt->get_result();

while ($p = $pRes->fetch_assoc()) {
    $totalAssigned++;
    if ($p['status'] === 'Delivered' && date('Y-m-d', strtotime($p['updated_at'])) === $todayDate) {
        $deliveredToday++;
    }
    if ($p['payment_status'] === 'COD' && $p['status'] !== 'Delivered') {
        $pendingCod += (float)$p['amount'];
    }
}
$pStmt->close();

json_response([
    'success' => true,
    'user' => [
        'id' => $userId,
        'name' => htmlspecialchars($user['name'], ENT_QUOTES, 'UTF-8'),
        'email' => htmlspecialchars($user['email'], ENT_QUOTES, 'UTF-8'),
        'phone' => htmlspecialchars($user['phone'] ?? 'N/A', ENT_QUOTES, 'UTF-8'),
        'role' => $user['role'],
        'status' => (int)$user['status'],
        'profile_image' => $avatarUrl,
        'branch' => $branchData,
        'stats' => [
            'total_assigned' => $totalAssigned,
            'delivered_today' => $deliveredToday,
            'pending_cod' => $pendingCod
        ]
    ]
]);
