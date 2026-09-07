<?php
/**
 * Cheetah Driver & Picker Mobile App - Forgot Password Endpoint
 * 
 * Simulates password recovery notification dispatch.
 */

require_once __DIR__ . '/../../../config.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed. Use POST.', 405);
}

$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);
if (!is_array($data)) {
    $data = $_POST;
}

$email = strtolower(trim((string)($data['email'] ?? '')));

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_error('A valid email address is required.', 400);
}

// Check if user exists (generic response for security)
$stmt = $conn->prepare("SELECT id, name FROM users WHERE email = ? AND role IN ('driver', 'picker') LIMIT 1");
$stmt->bind_param('s', $email);
$stmt->execute();
$exists = ($stmt->get_result()->num_rows > 0);
$stmt->close();

json_response([
    'success' => true,
    'status' => 'success',
    'message' => 'If an active account exists with this email, reset instructions have been sent.'
]);
