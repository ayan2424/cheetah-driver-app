<?php
/**
 * Cheetah Driver & Picker Mobile App - Standalone Backend Configuration
 * 
 * Production-ready configuration and database connection handler for the
 * Cheetah Delivery Driver & Warehouse Picker Mobile Suite.
 * 
 * Features:
 * - Pure PHP 8.0+ with mysqli (Zero framework overhead)
 * - Built-in CORS negotiation for cross-platform mobile HTTP requests
 * - Bearer token extraction across Apache, Nginx, LiteSpeed, and PHP built-in server
 * - Safe JSON error handlers preventing HTML bleed in captive portals
 */

// 1. Strict Error Handling & JSON Safety
error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED);
ini_set('display_errors', '0');
ini_set('log_errors', '1');

// 2. Global CORS & Security Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept, X-Requested-With, Origin');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

// Respond to preflight OPTIONS requests immediately
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 3. Database Credentials
// Update these settings to match your MySQL database credentials
define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');
define('DB_NAME', getenv('DB_NAME') ?: 'cheetah_driver_db');
define('DB_PORT', (int)(getenv('DB_PORT') ?: 3306));

// 4. Base URL Detection
$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443);
$protocol = $isHttps ? 'https://' : 'http://';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$scriptDir = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');
// Traverse up to backend root
$backendRoot = preg_replace('#/api/v1/(driver|picker).*$#', '', $scriptDir);
define('BASE_URL', $protocol . $host . $backendRoot . '/');

// 5. Establish MySQLi Database Connection
mysqli_report(MYSQLI_REPORT_OFF); // Prevent unhandled mysqli exceptions from spewing HTML
$conn = @new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);

if ($conn->connect_error) {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failure. Please verify database credentials in config.php.'
    ]);
    exit;
}

$conn->set_charset('utf8mb4');

// 6. Ensure Storage Upload Directories Exist
$uploadDirs = [
    __DIR__ . '/uploads',
    __DIR__ . '/uploads/pod',
    __DIR__ . '/uploads/signatures',
    __DIR__ . '/uploads/profiles'
];
foreach ($uploadDirs as $dir) {
    if (!is_dir($dir)) {
        @mkdir($dir, 0755, true);
    }
}

// 7. Helper: Extract API Bearer Token
if (!function_exists('driver_api_token')) {
    function driver_api_token(): string
    {
        $authorization = (string)(
            $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? ''
        );

        if (preg_match('/^Bearer\s+(.+)$/i', $authorization, $matches)) {
            return trim($matches[1]);
        }

        // Fallback for clients submitting via form/query parameter
        return trim((string)($_POST['api_token'] ?? $_GET['api_token'] ?? ''));
    }
}

// 8. Helper: Authenticate Driver or Picker via Bearer Token
if (!function_exists('get_authenticated_user')) {
    function get_authenticated_user(mysqli $conn, array $allowedRoles = ['driver', 'picker']): ?array
    {
        $token = driver_api_token();
        if (empty($token)) {
            return null;
        }

        $tokenHash = hash('sha256', $token);
        $stmt = $conn->prepare("SELECT id, name, email, phone, role, status, branch_id, profile_image 
                                FROM users 
                                WHERE api_token_hash = ? AND api_token_expires_at > NOW() AND status = 1 
                                LIMIT 1");
        if (!$stmt) {
            return null;
        }

        $stmt->bind_param('s', $tokenHash);
        $stmt->execute();
        $res = $stmt->get_result();

        if ($res->num_rows === 0) {
            $stmt->close();
            return null;
        }

        $user = $res->fetch_assoc();
        $stmt->close();

        if (!in_array($user['role'], $allowedRoles, true)) {
            return null;
        }

        return $user;
    }
}

// 9. Helper: Standardized JSON Output
if (!function_exists('json_response')) {
    function json_response(array $data, int $statusCode = 200): void
    {
        header('Content-Type: application/json; charset=utf-8');
        http_response_code($statusCode);
        echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        exit;
    }
}

if (!function_exists('json_error')) {
    function json_error(string $message, int $statusCode = 400): void
    {
        json_response(['success' => false, 'error' => $message], $statusCode);
    }
}
