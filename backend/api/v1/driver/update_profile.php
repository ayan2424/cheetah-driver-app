<?php
/**
 * Cheetah Driver & Picker Mobile App - Update Profile Endpoint
 * 
 * Allows couriers to update name, contact phone, preset avatars, or upload custom photos.
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
$name = trim((string)($_POST['name'] ?? ''));
$phone = trim((string)($_POST['phone'] ?? ''));
$presetAvatar = trim((string)($_POST['preset_avatar'] ?? ''));

$profileImage = $user['profile_image'];

// 1. Check Preset Avatar selection
if (!empty($presetAvatar)) {
    $profileImage = $presetAvatar;
}

// 2. Check Custom File Upload
if (isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] === UPLOAD_ERR_OK) {
    $tmpName = $_FILES['profile_image']['tmp_name'];
    $originalName = $_FILES['profile_image']['name'];
    $size = $_FILES['profile_image']['size'];

    $ext = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
    if (in_array($ext, ['jpg', 'jpeg', 'png', 'webp'], true) && $size <= 5 * 1024 * 1024) {
        $safeName = 'avatar_' . $userId . '_' . time() . '.' . $ext;
        $dest = __DIR__ . '/../../../uploads/profiles/' . $safeName;
        if (move_uploaded_file($tmpName, $dest)) {
            $profileImage = 'uploads/profiles/' . $safeName;
        }
    }
}

// 3. Update Database
$updateSql = "UPDATE users SET 
                name = CASE WHEN ? != '' THEN ? ELSE name END,
                phone = CASE WHEN ? != '' THEN ? ELSE phone END,
                profile_image = ?
              WHERE id = ?";

$stmt = $conn->prepare($updateSql);
$stmt->bind_param('sssssi', $name, $name, $phone, $phone, $profileImage, $userId);
$stmt->execute();
$stmt->close();

$avatarUrl = null;
if (!empty($profileImage)) {
    $avatarUrl = str_starts_with($profileImage, 'http')
        ? $profileImage
        : BASE_URL . ltrim($profileImage, '/');
}

json_response([
    'success' => true,
    'message' => 'Profile updated successfully.',
    'profile_image' => $avatarUrl
]);
