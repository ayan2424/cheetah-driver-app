<?php
/**
 * Cheetah Driver & Picker Mobile App - Change Password Endpoint
 * 
 * Verifies current password and updates to new password hash.
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

// Parse input
$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);
if (!is_array($data)) {
    $data = $_POST;
}

$currentPassword = (string)($data['current_password'] ?? '');
$newPassword = (string)($data['new_password'] ?? '');

if (empty($currentPassword) || empty($newPassword)) {
    json_error('Current password and new password are required.', 400);
}

if (strlen($newPassword) < 6) {
    json_error('New password must be at least 6 characters long.', 400);
}

// 1. Fetch current password hash
$stmt = $conn->prepare("SELECT password FROM users WHERE id = ? LIMIT 1");
$stmt->bind_param('i', $userId);
$stmt->execute();
$currentHash = $stmt->get_result()->fetch_assoc()['password'] ?? '';
$stmt->close();

if (!password_verify($currentPassword, $currentHash)) {
    json_error('The current password entered is incorrect.', 401);
}

// 2. Update with new hash
$newHash = password_hash($newPassword, PASSWORD_DEFAULT);
$upStmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
$upStmt->bind_param('si', $newHash, $userId);
$upStmt->execute();
$upStmt->close();

json_response([
    'success' => true,
    'message' => 'Password has been updated successfully.'
]);
