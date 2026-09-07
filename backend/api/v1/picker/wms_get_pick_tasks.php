<?php
/**
 * Cheetah Driver & Picker Mobile App - Get Warehouse Pick Tasks Endpoint
 * 
 * Fetches batch order fulfillment tasks assigned to the authenticated warehouse picker.
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

// Query pick tasks
$sql = "SELECT t.id, t.order_id, t.status, t.total_items, t.picked_items, t.notes, t.created_at,
               o.order_number, o.customer_name, o.customer_address,
               s.name AS store_name
        FROM wms_pick_tasks t
        JOIN wms_sales_orders o ON t.order_id = o.id
        LEFT JOIN wms_stores s ON o.store_id = s.id
        WHERE t.picker_id = ?
        ORDER BY 
            CASE 
                WHEN t.status = 'Pending' THEN 1 
                WHEN t.status = 'In Progress' THEN 2 
                ELSE 3 
            END,
            t.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $pickerId);
$stmt->execute();
$res = $stmt->get_result();

$tasks = [];
while ($row = $res->fetch_assoc()) {
    $tasks[] = [
        'id' => (int)$row['id'],
        'order_id' => (int)$row['order_id'],
        'order_number' => $row['order_number'],
        'store_name' => $row['store_name'] ?? 'Warehouse Stock',
        'customer_name' => $row['customer_name'] ?? '',
        'customer_address' => $row['customer_address'] ?? '',
        'status' => $row['status'],
        'total_items' => (int)$row['total_items'],
        'picked_items' => (int)$row['picked_items'],
        'notes' => $row['notes'] ?? '',
        'created_at' => $row['created_at']
    ];
}
$stmt->close();

json_response([
    'success' => true,
    'tasks' => $tasks
]);
