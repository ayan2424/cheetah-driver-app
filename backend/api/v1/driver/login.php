<?php
/**
 * Cheetah Driver & Picker Mobile App - Login Endpoint
 * 
 * Authenticates delivery drivers and warehouse pickers.
 * Returns a 30-day SHA-256 cryptographically secure Bearer token.
 */

require_once __DIR__ . '/../../../config.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed. Use POST.', 405);
}

// 1. Parse Input (Supports JSON payload and multipart/urlencoded POST)
$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);
if (!is_array($data)) {
    $data = $_POST;
}

$email = strtolower(trim((string)($data['email'] ?? '')));
$password = (string)($data['password'] ?? '');

if (empty($email) || empty($password) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_error('A valid email and password are required.', 400);
}

$clientIp = (string)($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');

// 2. Brute-Force Rate Limiting (Max 10 failed attempts per 5 minutes)
$windowStart = date('Y-m-d H:i:s', time() - (5 * 60));
$rateStmt = $conn->prepare("SELECT COUNT(*) AS cnt FROM driver_login_attempts WHERE (email = ? OR ip_address = ?) AND attempted_at >= ?");
if ($rateStmt) {
    $rateStmt->bind_param('sss', $email, $clientIp, $windowStart);
    $rateStmt->execute();
    $attemptCount = (int)($rateStmt->get_result()->fetch_assoc()['cnt'] ?? 0);
    $rateStmt->close();

    if ($attemptCount >= 10) {
        json_error('Too many failed login attempts. Please wait 5 minutes before retrying.', 429);
    }
}

// 3. Query User Record
$stmt = $conn->prepare("SELECT id, name, email, phone, password, role, status, branch_id, profile_image 
                        FROM users 
                        WHERE email = ? 
                        LIMIT 1");
$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    // Record failure
    $failStmt = $conn->prepare("INSERT INTO driver_login_attempts (email, ip_address) VALUES (?, ?)");
    if ($failStmt) {
        $failStmt->bind_param('ss', $email, $clientIp);
        $failStmt->execute();
        $failStmt->close();
    }
    json_error('Invalid email or password.', 401);
}

$user = $result->fetch_assoc();
$stmt->close();

// 4. Verify Password Hash
if (!password_verify($password, $user['password'])) {
    $failStmt = $conn->prepare("INSERT INTO driver_login_attempts (email, ip_address) VALUES (?, ?)");
    if ($failStmt) {
        $failStmt->bind_param('ss', $email, $clientIp);
        $failStmt->execute();
        $failStmt->close();
    }
    json_error('Invalid email or password.', 401);
}

// 5. Account Active Verification
if ((int)$user['status'] !== 1) {
    json_error('Your account is currently inactive or suspended. Please contact dispatch.', 403);
}

// 6. Role Authorization
if (!in_array($user['role'], ['driver', 'picker'], true)) {
    json_error('Access denied. This mobile application is strictly for drivers and pickers.', 403);
}

// 7. Generate Cryptographic 30-Day Bearer Token
$token = bin2hex(random_bytes(32));
$tokenHash = hash('sha256', $token);

$updateStmt = $conn->prepare("UPDATE users SET api_token = NULL, api_token_hash = ?, api_token_expires_at = DATE_ADD(NOW(), INTERVAL 30 DAY) WHERE id = ?");
$updateStmt->bind_param('si', $tokenHash, $user['id']);
$updateStmt->execute();
$updateStmt->close();

// 8. Clear Failed Login Attempts on Success
$clearStmt = $conn->prepare("DELETE FROM driver_login_attempts WHERE email = ?");
if ($clearStmt) {
    $clearStmt->bind_param('s', $email);
    $clearStmt->execute();
    $clearStmt->close();
}

// 9. Format Avatar URL
$avatarUrl = null;
if (!empty($user['profile_image'])) {
    $avatarUrl = str_starts_with($user['profile_image'], 'http') 
        ? $user['profile_image'] 
        : BASE_URL . ltrim($user['profile_image'], '/');
} else {
    $avatarUrl = "https://ui-avatars.com/api/?name=" . urlencode($user['name']) . "&background=FF4D00&color=fff&size=200";
}

// 10. Return Successful Response
json_response([
    'success' => true,
    'token' => $token,
    'api_token' => $token,
    'user' => [
        'id' => (int)$user['id'],
        'name' => htmlspecialchars($user['name'], ENT_QUOTES, 'UTF-8'),
        'email' => htmlspecialchars($user['email'], ENT_QUOTES, 'UTF-8'),
        'phone' => htmlspecialchars($user['phone'] ?? '', ENT_QUOTES, 'UTF-8'),
        'role' => $user['role'],
        'status' => (int)$user['status'],
        'branch_id' => (int)$user['branch_id'],
        'profile_image' => $avatarUrl
    ]
]);
