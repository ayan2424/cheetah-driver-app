<?php
/**
 * Cheetah Driver & Picker Mobile App - Update Warehouse Pick Task Endpoint
 * 
 * Advances pick task status and coordinates with parent sales order fulfillment.
 */

require_once __DIR__ . '/../../../config.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed. Use POST.', 405);
}

$user = get_authenticated_user($conn, ['picker', 'driver', 'admin']);
if (!$user) {
    json_error('Invalid or expired authentication token.', 401);
}

$pickerId = (int)$user['id'];

// Extract JSON or POST payload
$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);
if (!is_array($data)) {
    $data = $_POST;
}

$taskId = (int)($data['task_id'] ?? 0);
$newStatus = trim((string)($data['status'] ?? ''));

$allowedStatuses = ['Pending', 'In Progress', 'Completed'];

if ($taskId <= 0 || !in_array($newStatus, $allowedStatuses, true)) {
    json_error('A valid task_id and allowed status (Pending, In Progress, Completed) are required.', 400);
}

// 1. Verify task belongs to this picker
$checkStmt = $conn->prepare("SELECT id, order_id, status FROM wms_pick_tasks WHERE id = ? AND picker_id = ? LIMIT 1");
$checkStmt->bind_param('ii', $taskId, $pickerId);
$checkStmt->execute();
$taskRes = $checkStmt->get_result();

if ($taskRes->num_rows === 0) {
    $checkStmt->close();
    json_error('Task not found or not assigned to your picker profile.', 404);
}

$task = $taskRes->fetch_assoc();
$checkStmt->close();
$orderId = (int)$task['order_id'];

// 2. Update Pick Task Status
$updateStmt = $conn->prepare("UPDATE wms_pick_tasks SET status = ?, updated_at = NOW() WHERE id = ?");
$updateStmt->bind_param('si', $newStatus, $taskId);
$updateStmt->execute();
$updateStmt->close();

// 3. Coordinate with Parent Sales Order
if ($newStatus === 'Completed') {
    $soStmt = $conn->prepare("UPDATE wms_sales_orders SET status = 'Prepared', updated_at = NOW() WHERE id = ?");
    $soStmt->bind_param('i', $orderId);
    $soStmt->execute();
    $soStmt->close();
} elseif ($newStatus === 'In Progress') {
    $soStmt = $conn->prepare("UPDATE wms_sales_orders SET status = 'Picking', updated_at = NOW() WHERE id = ? AND status = 'Allocated'");
    $soStmt->bind_param('i', $orderId);
    $soStmt->execute();
    $soStmt->close();
}

json_response([
    'success' => true,
    'message' => "Pick task successfully transitioned to {$newStatus}.",
    'task_id' => $taskId,
    'new_status' => $newStatus
]);
