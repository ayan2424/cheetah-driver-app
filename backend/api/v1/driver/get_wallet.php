<?php
/**
 * Cheetah Driver & Picker Mobile App - Driver Wallet Endpoint
 * 
 * Returns driver earnings, unremitted COD cash balances, and recent commissions ledger.
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
$userRole = (string)$user['role'];

// If picker, return clean empty wallet payload
if ($userRole === 'picker') {
    json_response([
        'success' => true,
        'wallet' => [
            'pending_balance' => 0.00,
            'total_earned' => 0.00,
            'total_paid' => 0.00,
            'pending_cod' => 0.00,
            'history' => []
        ]
    ]);
}

// 1. Fetch Wallet Overview
$walletStmt = $conn->prepare("SELECT balance, pending_cod, total_withdrawn FROM driver_wallets WHERE driver_id = ? LIMIT 1");
$walletStmt->bind_param('i', $driverId);
$walletStmt->execute();
$walletRes = $walletStmt->get_result()->fetch_assoc();
$walletStmt->close();

$balance = (float)($walletRes['balance'] ?? 0.00);
$pendingCod = (float)($walletRes['pending_cod'] ?? 0.00);
$totalWithdrawn = (float)($walletRes['total_withdrawn'] ?? 0.00);

// 2. Fetch Total Commissions Summary
$commStmt = $conn->prepare("SELECT 
                                COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0) AS pending_comm,
                                COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0) AS paid_comm,
                                COALESCE(SUM(amount), 0) AS total_comm
                            FROM driver_commissions 
                            WHERE driver_id = ?");
$commStmt->bind_param('i', $driverId);
$commStmt->execute();
$commRow = $commStmt->get_result()->fetch_assoc();
$commStmt->close();

$pendingBalance = (float)($commRow['pending_comm'] ?? 0.00);
$totalEarned = (float)($commRow['total_comm'] ?? 0.00);
$totalPaid = (float)($commRow['paid_comm'] ?? 0.00);

// 3. Fetch Recent Commission & Payout History
$historyStmt = $conn->prepare("
    SELECT c.id, c.amount, c.status, c.created_at, c.paid_at, p.tracking_number 
    FROM driver_commissions c 
    LEFT JOIN parcels p ON p.id = c.parcel_id 
    WHERE c.driver_id = ? 
    ORDER BY c.created_at DESC 
    LIMIT 30
");
$historyStmt->bind_param('i', $driverId);
$historyStmt->execute();
$historyRes = $historyStmt->get_result();

$history = [];
while ($row = $historyRes->fetch_assoc()) {
    $history[] = [
        'id' => (int)$row['id'],
        'amount' => (float)$row['amount'],
        'status' => $row['status'],
        'tracking_number' => $row['tracking_number'] ?? 'N/A',
        'date' => $row['created_at'],
        'paid_at' => $row['paid_at']
    ];
}
$historyStmt->close();

json_response([
    'success' => true,
    'wallet' => [
        'pending_balance' => $pendingBalance,
        'total_earned' => $totalEarned,
        'total_paid' => $totalPaid,
        'pending_cod' => $pendingCod,
        'available_balance' => $balance,
        'history' => $history
    ]
]);
