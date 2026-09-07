# 🛵 Cheetah Driver & Picker Mobile App — Standalone REST API Backend

Welcome to the official standalone REST API backend for the **Cheetah Delivery Driver & Warehouse Picker Mobile Suite (Flutter 3.x)**.

This lightweight backend provides everything needed to host and operate the mobile application independently on any standard cPanel, Apache, LiteSpeed, Nginx, or VPS server without requiring third-party SaaS subscriptions.

---

## 📁 Package Architecture

```text
backend/
├── config.php                  # Database connection, CORS, auth helpers & error handlers
├── database/
│   └── driver_app.sql          # Dedicated schema with pre-seeded demo drivers, pickers & parcels
├── api/
│   └── v1/
│       ├── driver/
│       │   ├── login.php           # Token issuance with rate limiting & SHA-256 hashing
│       │   ├── logout.php          # Invalidate active Bearer token
│       │   ├── get_parcels.php     # Fetch assigned deliveries with live KPI summary
│       │   ├── update_status.php   # Status progression, signature & photo POD, OTP & COD settlement
│       │   ├── update_location.php # Real-time GPS telemetry & anti-tampering alerts
│       │   ├── get_wallet.php      # Driver COD ledger & commission earnings history
│       │   ├── get_profile.php     # Full profile, vehicle assignment & branch data
│       │   ├── update_profile.php  # Name, contact phone, avatar presets or custom upload
│       │   ├── change_password.php # Secure password update with current hash validation
│       │   ├── forgot_password.php # Recovery notification simulator
│       │   └── update_fcm_token.php# Firebase Cloud Messaging token synchronizer
│       └── picker/
│           ├── wms_get_pick_tasks.php # Queue of assigned sales order picking tasks
│           └── wms_update_task.php    # Task status progression & sales order coordination
└── uploads/
    ├── pod/                    # Consignee drop-off photos
    ├── signatures/             # Touchscreen digital signature PNGs
    └── profiles/               # Custom driver & picker profile avatars
```

---

## 🚀 5-Minute Fast Deployment Guide

### Step 1: Import MySQL Database
1. Open your hosting control panel (**cPanel / phpMyAdmin / Adminer / MySQL CLI**).
2. Create a new database (e.g., `cheetah_mobile_db`).
3. Click **Import** and select `database/driver_app.sql` from this folder.
4. Click **Go / Import**. All tables and pre-seeded demo records will be installed immediately.

### Step 2: Configure Database Connection
Open `config.php` in any text editor and enter your database credentials:

```php
// 3. Database Credentials
define('DB_HOST', 'localhost');          // Usually localhost
define('DB_USER', 'your_db_user');       // Your MySQL username
define('DB_PASS', 'your_db_password');   // Your MySQL password
define('DB_NAME', 'cheetah_mobile_db');  // Your database name
define('DB_PORT', 3306);                 // MySQL Port (3306)
```

### Step 3: Upload Backend to Your Web Server
Upload the contents of the `backend/` folder to your public directory:
- If hosting on a subdomain (e.g., `https://api.yourdomain.com/`), upload files directly into the root folder.
- If hosting in a subfolder (e.g., `https://yourdomain.com/cheetah_api/`), upload files into `cheetah_api/`.

Ensure the `uploads/` directory has write permissions (**0755** or **0775**).

### Step 4: Connect the Flutter Mobile App
Open `lib/utils/constants.dart` in the Flutter mobile app source code and update the `_envBaseUrl`:

```dart
static const String _envBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://api.yourdomain.com/', // Put your backend URL here
);
```

Or build the release APK with the environment flag:
```bash
flutter build apk --release --dart-define=BASE_URL=https://api.yourdomain.com/
```

---

## 🔑 Pre-Seeded Demo Accounts

| Role | Email | Password | Assigned Scope |
| :--- | :--- | :--- | :--- |
| 🛵 **Delivery Driver** | `rider@cheetah.com` | `Rider123` | Karachi Central Hub (5 Active Parcels) |
| 🏭 **Warehouse Picker** | `picker@cheetah.com` | `Picker123` | Karachi Central Hub (2 WMS Pick Tasks) |

---

## 🧪 Testing with Postman
An official Postman Collection is provided in `postman/`:
1. Import `postman/Cheetah_Driver_App_API.postman_collection.json` into Postman.
2. Import `postman/Cheetah_Driver_App_Environment.postman_environment.json`.
3. Set your `base_url` in the Postman Environment.
4. Run the **Driver Login** request. The test script will automatically capture and set the `{{bearer_token}}` variable for all subsequent requests.

---

## 🛡️ Security Best Practices
- **Prepared Statements:** 100% of SQL queries utilize `mysqli` prepared statements to prevent SQL injection.
- **SHA-256 Bearer Tokens:** Tokens are stored as SHA-256 hashes at rest with an automated 30-day expiration window.
- **Brute-Force Rate Limiting:** Login requests are strictly rate-limited (10 failed attempts per 5 minutes per IP/email).
- **Strict Role Isolation:** Drivers can only view shipments assigned to their unique ID.
