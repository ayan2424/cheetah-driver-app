<?php
/**
 * Cheetah Driver & Picker Mobile App - FCM Push Notification Token Sync
 * 
 * Registers device Firebase Cloud Messaging registration token for background dispatch alerts.
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

// Extract token
$fcmToken = trim((string)($_POST['fcm_token'] ?? ''));
if (empty($fcmToken)) {
    $rawInput = file_get_contents('php://input');
    $data = json_decode($rawInput, true);
    if (is_array($data)) {
        $fcmToken = trim((string)($data['fcm_token'] ?? ''));
    }
}

if (empty($fcmToken)) {
    json_error('FCM device token is required.', 400);
}

$stmt = $conn->prepare("UPDATE users SET fcm_token = ? WHERE id = ?");
$stmt->bind_param('si', $fcmToken, $userId);
$stmt->execute();
$stmt->close();

json_response([
    'success' => true,
    'message' => 'FCM push registration token synchronized successfully.'
]);
