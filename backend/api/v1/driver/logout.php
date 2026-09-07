<?php
/**
 * Cheetah Driver & Picker Mobile App - Logout Endpoint
 * 
 * Securely revokes the active Bearer token from the database.
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

// Invalidate token
$stmt = $conn->prepare("UPDATE users SET api_token = NULL, api_token_hash = NULL, api_token_expires_at = NULL WHERE id = ?");
$stmt->bind_param('i', $user['id']);
$stmt->execute();
$stmt->close();

json_response([
    'success' => true,
    'message' => 'Successfully logged out.'
]);
