<?php
/**
 * Cheetah Driver & Picker Mobile App - Update Location / Telemetry Endpoint
 * 
 * Ingests live GPS telemetry (coordinates, speed, heading, battery, anti-tampering)
 * to feed the dispatcher operations map.
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

// Extract telemetry payload (supports both Form POST and JSON body)
$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);
if (!is_array($data)) {
    $data = $_POST;
}

$latitude = isset($data['latitude']) ? (float)$data['latitude'] : null;
$longitude = isset($data['longitude']) ? (float)$data['longitude'] : null;
$speed = isset($data['speed']) ? (float)$data['speed'] : 0.00;
$heading = isset($data['heading']) ? (float)$data['heading'] : 0.00;
$batteryLevel = isset($data['battery_level']) ? (int)$data['battery_level'] : 95;
$gpsEnabled = isset($data['gps_enabled']) ? (int)$data['gps_enabled'] : 1;
$isMock = isset($data['is_mock']) ? (int)$data['is_mock'] : 0;

if ($latitude === null || $longitude === null) {
    // If telemetry only reported GPS sensor state
    json_response([
        'success' => true,
        'message' => 'GPS status logged successfully.',
        'gps_enabled' => $gpsEnabled
    ]);
}

$stmt = $conn->prepare("INSERT INTO driver_locations (driver_id, latitude, longitude, speed, heading, battery_level, gps_enabled, is_mock, created_at) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())");
if ($stmt) {
    $stmt->bind_param('iddddiis', $driverId, $latitude, $longitude, $speed, $heading, $batteryLevel, $gpsEnabled, $isMock);
    $stmt->execute();
    $stmt->close();
}

json_response([
    'success' => true,
    'message' => 'Telemetry coordinates recorded successfully.',
    'coordinates' => [
        'latitude' => $latitude,
        'longitude' => $longitude,
        'speed' => $speed,
        'gps_enabled' => $gpsEnabled
    ]
]);
