# 🐆 Cheetah Driver & Picker Mobile App — Senior Mobile Systems & Technical Architecture Specification

> **Target Audience:** Senior Mobile Systems Engineers, Lead Developers, & Commercial Integrators.  
> **Purpose:** Exhaustive architectural reference, internal state machines, hardware security models, cryptographic sync protocols, and backend API contracts.  
> **Note:** End-user/buyer documentation is packaged separately in `Documentation.html`. This document is the definitive engineering source of truth for the Flutter codebase.

---

## 📑 Technical Blueprint Index

1. [Architectural Philosophy & Patterns](#1-architectural-philosophy--patterns)
2. [Reactive State & Lifecycle Engine (GetX)](#2-reactive-state--lifecycle-engine-getx)
3. [Offline-First POD Cryptographic Bus (Hive AES-256)](#3-offline-first-pod-cryptographic-bus-hive-aes-256)
4. [Hardware Enclave & Authentication Lifecycle](#4-hardware-enclave--authentication-lifecycle)
5. [GPS Telemetry Stream & Native Hardware Guard](#5-gps-telemetry-stream--native-hardware-guard)
6. [Dual-Persona Execution Engine (Driver vs Picker)](#6-dual-persona-execution-engine-driver-vs-picker)
7. [REST API Contract & Wire Specifications](#7-rest-api-contract--wire-specifications)
8. [Non-Repudiation Watermarking Pipeline](#8-non-repudiation-watermarking-pipeline)
9. [Error Boundary & Fault-Tolerance Principles](#9-error-boundary--fault-tolerance-principles)
10. [Firebase Push Notification Architecture & Fallback](#10-firebase-push-notification-architecture--fallback)
11. [Developer Extension & Maintenance Guidelines](#11-developer-extension--maintenance-guidelines)
12. [v10.0 Commercial Release Synchronization](#12-v100-commercial-release-synchronization)

---

## 1. Architectural Philosophy & Patterns

The **Cheetah Mobile Client** is structured under a strict **Model-View-ViewModel (MVVM)** separation of concerns, decoupled from the backend via dedicated service adapters:

```
[ Native OS Platforms (Android / iOS) ]
                  │ (Hardware Channels: Location, Keystore, Camera, Connectivity)
                  ▼
[ Low-Level Infrastructure Services (`lib/services/`) ]
  ├── SessionStore (Keystore/Keychain token isolation)
  ├── OfflineSyncService (Hive AES-256 encrypted queue)
  ├── LocationService (30s cadence + <0.1s hardware kill-switch stream)
  ├── FirebaseService (Crash-safe standalone push adapter)
  └── ApiService (Sanitized HTTP REST transport, 15s bounded timeout)
                  │
                  ▼
[ Reactive State & ViewModels (`lib/controllers/`) ]
  ├── AuthController (Session hydration, RBAC, theme, localization, lifecycle observer)
  ├── ParcelController (Manifest state, in-memory search, offline POD intercept)
  ├── PickingController (WMS pick wave state machine & bin traversal)
  └── WalletController (COD ledger reconciliation & driver commissions)
                  │
                  ▼
[ Declarative Presentation Layer (`lib/views/`) ]
  ├── Views: SplashView, LoginView, HomeView
  └── Components: QrScannerView, DeliveriesTab, CodTab, PickingTab
```

### Core Architecture Invariants
- **No Direct SQLite in UI:** UI components never read or write local storage directly; all persistence flows through `SessionStore` or `OfflineSyncService`.
- **Zero-Token Storage in Payloads:** Offline queue payloads must **never** embed authorization tokens to prevent credential exposure or stale replay.
- **Fail-Safe Standalone Operation:** The app must compile and run 100% functionally even if third-party services (like Firebase FCM) are unconfigured.

---

## 2. Reactive State & Lifecycle Engine (GetX)

The application utilizes **GetX (`get: ^4.6.6`)** for dependency injection, reactive state propagation, and micro-routing.

### Dependency Graph & Initialization
```dart
// Bootstrapped in main.dart:
Get.put(AuthController(), permanent: true); // Persistent root session owner
```

### Lifecycle Observability (`WidgetsBindingObserver`)
`AuthController` extends `GetxController` with `WidgetsBindingObserver`:
1. `didChangeAppLifecycleState(AppLifecycleState.resumed)`:
   - Re-checks native GPS hardware toggles via `LocationService.checkAndEnforceLocationState()`.
   - Re-synchronizes platform brightness dispatcher if `themePreference == 'system'`.
2. `didChangePlatformBrightness()`:
   - Triggers dynamic HSL palette adjustments in real time without requiring application reload.

---

## 3. Offline-First POD Cryptographic Bus (Hive AES-256)

### Storage Mechanics
When couriers operate in dead zones (basements, metal cargo containers, elevators), `ParcelController.submitPod()` intercepts the offline state via `connectivity_plus` and redirects the payload to `OfflineSyncService`.

```
[ Driver Submits POD ]
         │
         ▼
[ Network Check (ConnectivityResult.none) ]
   ├── (Online) ──> Transmit directly via `ApiService.updateStatusWithPod()`
   │
   └── (Offline) ──> Serialize Payload (Local Image Path + Base64 Signature + Recipient Data)
                           │
                           ▼
                     [ Hive Box: 'offline_pod_queue' ]
                     [ Encryption: HiveAesCipher(256-bit Key) ]
                     [ Key Storage: Android Keystore / iOS Keychain ]
```

### Auto-Sync Protocol
- `OfflineSyncService` maintains an active stream subscription:
  `Connectivity().onConnectivityChanged.listen(...)`
- When mobile data or Wi-Fi is detected, `syncPendingPods()` executes with an re-entrancy lock (`_isSyncing`).
- **Idempotency Rule:** Records are only deleted (`box.delete(key)`) upon receiving HTTP 200 `{ "success": true }` from the server. Network timeouts or server errors keep the payload safely queued for the next retry wave.

---

## 4. Hardware Enclave & Authentication Lifecycle

### Security Isolation
Authentication tokens are never stored in plaintext `SharedPreferences` (which are vulnerable to ADB extraction or rooted file inspection). `SessionStore` enforces hardware-backed secure storage:

| Platform | Underlying Security Provider | Cipher Algorithm |
| :--- | :--- | :--- |
| **Android** | Android Keystore Provider | AES-256 GCM with RSA Key-Wrapping |
| **iOS** | Apple Keychain (`kSecClassGenericPassword`) | Hardware Secure Enclave (AES-256) |

### Server-Side Zero-Knowledge Token Contract
1. On login, the server issues an unhashed token string to the client.
2. The server stores only its SHA-256 digest (`users.api_token_hash`) with a 30-day validity window (`users.api_token_expires_at > NOW()`).
3. On every API request, the client transmits `Authorization: Bearer <token>`.
4. If a session is revoked or expires, the server returns HTTP 401. `AuthController.handleSessionExpired()` halts GPS timers, purges secure enclave keys, and redirects to `LoginView`.

---

## 5. GPS Telemetry Stream & Native Hardware Guard

### 30-Second Polling Cadence Strategy
Field empirical analysis on active courier shifts established that a 30-second interval balances dispatcher live-map accuracy against device power draw:
- **Power Budget:** Consumes <4% battery/hour, supporting full 8–10 hour working shifts.
- **Cellular Bandwidth:** <1MB telemetry payload per working day.

### Real-Time Hardware Kill-Switch Guard
```dart
Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
  if (status == ServiceStatus.disabled) {
    // 1. Instant (<0.1s) hardware kill detection
    // 2. Dispatch tamper alert: gps_enabled = 0
    _sendGpsOffStatus(token);
    // 3. Render un-dismissible blocking modal
    _forceEnableGpsHardware();
  }
});
```

---

## 6. Dual-Persona Execution Engine (Driver vs Picker)

The client dynamically switches role behavior based on `authController.userRole`:

### 1. Courier Driver Persona (`userRole == 'driver'`)
- **Manifest Ingestion:** Queries `api/v1/driver/get_parcels.php` scoped strictly to `driver_id == user_id`.
- **Delivery Flow:** Signature canvas capture, doorstep photo proof, mandatory OTP verification on high-value orders.
- **Financial Reconciliation:** Cash on Delivery (COD) ledger tracking and commission earnings wallet.
- **Telemetry:** Continuous 30s background GPS updates.

### 2. Warehouse Picker Persona (`userRole == 'picker'`)
- **WMS Wave Ingestion:** Queries `api/v1/picker/wms_get_pick_tasks.php` scoped to `picker_id == user_id`.
- **Shelf Guidance:** Structured bin traversal: `Zone -> Aisle -> Shelf -> Bin`.
- **SKU Verification:** Barcode verification ensuring correct physical item selection.
- **Order State Progression:** Marking task `Completed` automatically transitions linked sales order to `Prepared` in Cheetah WMS.
- **Telemetry:** GPS streaming is completely disabled to conserve battery inside warehouse facilities.

---

## 7. REST API Contract & Wire Specifications

All endpoints communicate over HTTPS with `Accept: application/json` and `Authorization: Bearer <token>`.

### Key Endpoints Matrix

| Endpoint Route | Method | Payload / Headers | Description & Security Controls |
| :--- | :---: | :--- | :--- |
| `api/v1/driver/login.php` | `POST` | `email`, `password` | Authenticates user; returns bearer token, role, and branch info. Enforces 5-attempt / 5-min brute-force lockout window. |
| `api/v1/driver/get_parcels.php` | `POST` | Bearer Token | Fetches driver-scoped manifest and aggregated shift metrics. Supports branded `CHT-{ORIGIN_CODE}-{SERIAL}` tracking numbers. |
| `api/v1/driver/update_status.php` | `POST` (Multipart) | `tracking_number`, `status`, `photo`, `signature`, `delivery_otp` | Submits POD evidence, verifies state transitions, burns server-side non-repudiation watermark. |
| `api/v1/driver/update_location.php` | `POST` | `latitude`, `longitude`, `gps_enabled` | Telemetry ping updating central operations fleet map. Auto-alerts on hardware GPS disable. |
| `api/v1/driver/get_wallet.php` | `POST` | Bearer Token | Returns pending commissions, paid totals, and transaction log. Reconciles with backend double-spend idempotency engine. |
| `api/v1/driver/forgot_password.php` | `POST` | `email` | Initiates secure split-token password reset link via PHPMailer SMTP. |
| `api/v1/picker/wms_get_pick_tasks.php`| `POST`| Bearer Token | Ingests active warehouse picking waves and item SKU lists with 5-tier spatial bin coordinates (Zone, Aisle, Shelf, Bin). |
| `api/v1/picker/wms_update_task.php` | `POST` | `task_id`, `status` | Advances WMS task to `In Progress` or `Completed` (auto-transitions linked sales order to `Prepared`). |

---

## 8. Non-Repudiation Watermarking Pipeline

To prevent delivery dispute fraud, the backend executes cryptographic watermarking upon receiving multipart proof evidence:

```
[ Mobile Client ]
  ├── Photo Proof (JPEG/PNG raster)
  └── Vector Signature (PNG raw bytes)
         │
         ▼
[ Server GD Engine (`update_status.php`) ]
  ├── 1. Validates MIME type & dimensions (<=16MP, <=5MB)
  ├── 2. Creates semi-transparent black banner (alpha: 60)
  ├── 3. Overlays non-repudiation watermark:
  │      "POD: {tracking_number} | Date: {Y-m-d H:i:s} | Driver: {driver_name}"
  └── 4. Writes processed raster to `assets/uploads/proofs/`
```

---

## 9. Error Boundary & Fault-Tolerance Principles

1. **HTML Response Bleed Guard (`ApiService._decodeResponse`):**
   Catches captive Wi-Fi portals, cloudflare challenge pages, or PHP runtime fatal errors that output raw HTML `<...>` and prevents runtime JSON crash exceptions.
2. **Bounded Request Timeouts:**
   All network requests enforce a strict 15-second cutoff (`_requestTimeout`), allowing offline POD fallbacks to trigger immediately rather than freezing driver UI on the road.
3. **Async Gap Context Safety:**
   All async callbacks referencing `BuildContext` must precede with `if (!context.mounted) return;` to prevent memory leaks and unmounted widget tree crashes.

---

## 10. Firebase Push Notification Architecture & Fallback

The application features a robust **Dual-Mode Push Notification System** managed by `FirebaseService`:

1. **Standalone Mode (Default / Zero-Config):**
   - If `google-services.json` or `GoogleService-Info.plist` is not present, `FirebaseService` catches initialization gracefully without throwing uncaught exceptions.
   - The app continues to operate 100% normally via REST polling on manifest refresh.
2. **Firebase FCM Mode (Activated):**
   - When configured, FCM registers the device token on `login.php`.
   - The Cheetah backend SaaS automatically triggers push notifications on parcel assignments and WMS pick tasks.
   - For step-by-step buyer setup, refer to `FIREBASE_SETUP.md`.

---

## 11. Developer Extension & Maintenance Guidelines

When modifying or expanding this Flutter codebase:
1. **Preserve RBAC Branch Scoping:** Never bypass `driver_id` or `picker_id` validation.
2. **Synchronize Database Dumps:** If new API fields are added, ensure corresponding migrations and schema modifications are reflected in `database/cheetah.sql` and `database/cheetah_demo.sql`.
3. **No Unencrypted Queues:** Never store unencrypted sensitive payloads in local files or preferences. Always use `SessionStore` and `OfflineSyncService`.
4. **Maintain Static Analysis Standards:** Ensure `flutter analyze` passes with zero errors and zero warnings on all PRs.

---

## 12. v10.0 Commercial Release Synchronization

The Flutter mobile suite is fully synchronized with **Cheetah Courier & WMS SaaS v10.0 Commercial Release**:

| Feature Subsystem | Mobile Client Implementation | Backend Alignment |
| :--- | :--- | :--- |
| **Branded CHT- Tracking** | `QrScannerView` & `ParcelController` natively parse and display `CHT-{ORIGIN_CODE}-{SERIAL}` format. | Generated via `generate_tracking_number()` with row-locking concurrency in `system_settings`. |
| **WMS 5-Tier Spatial Routing** | `PickingTab` displays structured hierarchy: `Warehouse -> Zone -> Aisle -> Shelf -> Bin`. | Fed directly from `wms_bins`, `wms_shelves`, and `wms_aisles` tables in `admin/wms_spatial.php`. |
| **Double-Spend Idempotency** | Driver COD collections are recorded with unique UUID idempotency keys before vault handover. | Reconciled against `idempotency_keys` table to eliminate duplicate vouchers. |
| **19-Layer Defense-in-Depth** | Hardware-backed token storage in Android Keystore / iOS Keychain; unhashed tokens never saved locally. | SHA-256 hashed bearer tokens at rest (`users.api_token_hash`) with 30-day expiration windows. |
| **23-Language Internationalization** | Complete dictionary mappings with native RTL layout flipping (`Directionality` / RTL widgets) for Arabic and Urdu. | 1:1 match with SaaS web translations in `languages/*.json`. |
| **Target Platforms** | Android 15 (Target SDK 35, Min SDK 21), iOS 18 (Xcode 16 / CocoaPods 1.15+), and industrial rugged Android scanners. | Google Play 2026 & Apple App Store compliance verified. |
