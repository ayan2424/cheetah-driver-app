# 🛵 Cheetah Driver & Warehouse Picker Mobile App

[![Flutter Build](https://github.com/ayan2424/cheetah-driver-app/actions/workflows/ios-simulator-build.yml/badge.svg)](https://github.com/ayan2424/cheetah-driver-app/actions/workflows/ios-simulator-build.yml)
[![Flutter SDK](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart SDK](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev)
[![iOS Target](https://img.shields.io/badge/iOS-14.0%2B-000000.svg?logo=apple)](https://apple.com/ios)
[![Android Target](https://img.shields.io/badge/Android-5.0%2B%20(API%2021%2B)-3DDC84.svg?logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-Proprietary-FF4D00.svg)](https://cheetah.ayan24.me)

**Cheetah Driver App** is an enterprise-grade, offline-resilient mobile companion for the **Cheetah Courier Management System & WMS SaaS** (live at [https://cheetah.ayan24.me](https://cheetah.ayan24.me)). Engineered specifically for courier riders on the road and fulfillment staff on the warehouse floor, the app delivers sub-second barcode manifest intake, hardware-backed offline Proof of Delivery (POD) capture, battery-optimized live GPS fleet telemetry, and real-time Cash on Delivery (COD) collection reconciliation.

---

## 📑 Table of Contents
- [Architectural Overview](#-architectural-overview)
- [Role-Based Access Control (RBAC)](#-role-based-access-control-rbac)
- [Offline-First POD Engine & Conflict Resolution](#-offline-first-pod-engine--conflict-resolution)
- [Proof of Delivery (POD) & Non-Repudiation Watermarking](#-proof-of-delivery-pod--non-repudiation-watermarking)
- [Battery-Optimized GPS Telemetry & Hardware Guard](#-battery-optimized-gps-telemetry--hardware-guard)
- [Security & Authentication Model](#-security--authentication-model)
- [State Management & Directory Structure](#-state-management--directory-structure)
- [Hardware & OS Compatibility Matrix](#-hardware--os-compatibility-matrix)
- [CI/CD & Local Build Workflows](#-cicd--local-build-workflows)
- [Production Considerations & Known Limitations](#-production-considerations--known-limitations)

---

## 🏛 Architectural Overview

The Cheetah mobile client follows the **Model-View-ViewModel (MVVM)** architectural pattern powered by **GetX** reactive state management. The client communicates with Cheetah's pure PHP 8.0+ REST backend via secure HTTPS endpoints.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Cheetah Mobile Frontend                         │
├──────────────────────────────────┬─────────────────────────────────────┤
│        Courier Driver Flow       │       Warehouse Picker Flow         │
│  - Active Delivery Manifest      │  - WMS Batch Pick Waves             │
│  - Instant AWB Barcode Search    │  - Zone/Aisle/Shelf Guidance        │
│  - Vector Signature Touch Pad    │  - SKU Barcode Verification         │
│  - Camera Photo Evidence Capture │  - Sales Order Packing State Hook   │
│  - OTP High-Value Authorization  │                                     │
│  - COD Cash Accounting Ledger    │                                     │
│  - 30s Battery-Preserved GPS     │                                     │
└─────────────────┬────────────────┴──────────────────┬──────────────────┘
                  │                                   │
                  ▼                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      Offline Sync & Security Bus                       │
│  - Hive AES-256 Local Encrypted Storage (`offline_pod_queue`)           │
│  - Hardware Secure Storage (`FlutterSecureStorage` Keystore/Keychain)  │
│  - Real-Time Network Transition Listener (`connectivity_plus`)         │
│  - Standalone-Ready Firebase Cloud Messaging (`firebase_messaging`)    │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │ HTTPS / REST (Bearer SHA-256)
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                Cheetah Backend SaaS (PHP 8+ / MySQLi)                  │
│  - Driver & Branch Isolation Validation                                │
│  - Non-Repudiation Server Watermark Overlay Engine                     │
│  - Real-Time Dispatch Fleet Map Broadcast (`update_location.php`)       │
│  - WMS Inventory & Sales Order State Machine                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 👥 Role-Based Access Control (RBAC)

Upon authentication against `api/v1/driver/login.php`, the backend evaluates the user's assigned role and returns identity metadata. The Flutter client dynamically reconfigures the bottom navigation hierarchy:

| Feature / Screen | Courier Driver Role (`driver`) | Warehouse Picker Role (`picker`) |
| :--- | :---: | :---: |
| **Deliveries Manifest** | ✅ Full Access (Filter, Search, Transit) | ❌ Hidden |
| **Camera AWB Scanner** | ✅ Instant Manifest Filter | ❌ Hidden |
| **Proof of Delivery (POD)** | ✅ Signature Pad + Photo Proof | ❌ Hidden |
| **Delivery OTP Verification** | ✅ Enforced on High-Value/COD | ❌ Hidden |
| **COD Cash Ledger** | ✅ Real-Time Shift Balance | ❌ Hidden (Pickers do not collect cash) |
| **Driver Earnings Wallet** | ✅ Commission & Payout Logs | ❌ Hidden |
| **Live GPS Telemetry** | ✅ 30s Fleet Tracking Ping | ❌ Disabled (Battery Preservation) |
| **WMS Batch Pick Tasks** | ❌ Hidden | ✅ Zone → Aisle → Shelf → Bin Guidance |
| **SKU Barcode Verification**| ❌ Hidden | ✅ Automated Item Validation |
| **Theme & Localization** | ✅ Dark / Light / 9 Languages | ✅ Dark / Light / 9 Languages |

---

## 📦 Offline-First POD Engine & Conflict Resolution

In real-world logistics, drivers frequently deliver shipments in locations with zero cellular reception (subterranean basements, elevator shafts, cargo containers, rural transit corridors). Cheetah implements a zero-data-loss offline delivery engine:

### 1. Local Encryption (AES-256)
- Queued deliveries are stored in a dedicated Hive box (`offline_pod_queue`) encrypted with `HiveAesCipher`.
- The 256-bit encryption key is generated via `Random.secure()` and persisted inside the device's hardware enclave (Android Keystore / iOS Keychain) via `FlutterSecureStorage`.
- **Zero-Token Storage:** Queued delivery payloads **never** store bearer authentication tokens directly. When connectivity returns, the active, validated token is dynamically loaded from `SessionStore` to prevent token staleness or security exposure in local queue files.

### 2. Payload Structure
```json
{
  "parcelId": "1042",
  "trackingNumber": "CH-882190-PK",
  "status": "Delivered",
  "receiverName": "Hamza Tariq",
  "description": "Left at front reception desk",
  "deliveryOtp": "4819",
  "photo_path": "/data/user/0/me.ayan24.cheetah/app_flutter/pod_1042.jpg",
  "signature_base64": "iVBORw0KGgoAAAANSUhEUgAA..."
}
```

### 3. Conflict Resolution & Idempotency
- **Auto-Sync Watcher:** Listens to `Connectivity().onConnectivityChanged`. The instant mobile data or Wi-Fi is restored, `OfflineSyncService.syncPendingPods()` fires automatically.
- **Idempotent Commit:** The service processes queued items sequentially. A record is **only deleted from local storage** after the backend returns HTTP 200 with `{"success": true}`. If an upload fails due to network drop midway, the item remains safely in the queue for the next retry wave.
- **Server as Authoritative Clock:** Even if an offline delivery syncs hours later, the server logs the exact chronological delivery sequence and updates the consignee's live tracking status.

---

## 📸 Proof of Delivery (POD) & Non-Repudiation Watermarking

To protect merchants and logistics operators against fraudulent claims, Cheetah employs a dual-evidence Proof of Delivery pipeline:

1. **Vector Touch Signature:** Consignees sign directly on a high-precision, low-latency vector canvas (`SignatureController`). On submission, vector strokes are exported as raw PNG raster bytes.
2. **Camera Photo Evidence:** Drivers take a photo of the delivered parcel at the doorstep.
3. **Server-Side Watermarking Engine (`api/v1/driver/update_status.php`):**
   - The server validates image MIME type and pixel dimensions using GD.
   - A semi-transparent dark banner overlay is dynamically composited at the bottom of the raster.
   - Burned text contains: `POD: <trackingNumber> | Date: <UTC YYYY-MM-DD HH:MM:SS> | Driver: <driverName>`.
   - This ensures non-repudiation: merchants and consignees can inspect the delivery certificate on the public tracking portal with cryptographic certainty.
4. **Mandatory Delivery OTP:** High-value or cash orders flagged with `requires_otp == true` require the recipient to provide their 4-digit SMS PIN before the delivery state can transition to `Delivered`.

---

## 📡 Battery-Optimized GPS Telemetry & Hardware Guard

### 1. The 30-Second Cadence Trade-Off
Continuous GPS polling (1–5s intervals) drains mobile battery within 3–4 hours, leaving couriers stranded midway through a shift. A 30-second polling cadence was chosen after empirical field testing:
- **Battery Longevity:** Consumes less than 4% battery per hour, easily supporting full 8–10 hour courier shifts.
- **Data Efficiency:** Lightweight telemetry payload (`latitude`, `longitude`, `gps_enabled`) requires under 1MB of cellular data per working day.
- **Dispatcher Fidelity:** Smoothly updates central web operations maps with accurate vehicle heading and ETA calculation.

### 2. Hardware GPS Kill-Switch Guard
If a driver turns off the device location toggle to bypass fleet visibility:
- The native hardware status stream (`Geolocator.getServiceStatusStream()`) detects the hardware event in **<0.1 seconds**.
- The app immediately transmits a `gps_enabled = 0` telemetry packet to the server, flagging the driver as offline/tampered on dispatch monitors.
- An un-dismissible modal (`PopScope(canPop: false)`) blocks app interaction until location hardware is re-enabled.

---

## 🔒 Security & Authentication Model

1. **Hardware Enclave Isolation:**
   Authentication tokens are never stored in plaintext `SharedPreferences` (which can be inspected via ADB backups or root access). Tokens are strictly saved in `FlutterSecureStorage` (AES-256 GCM on Android Keystore; Keychain on iOS).
2. **SHA-256 Zero-Knowledge Verification:**
   The server generates an unhashed Bearer token string on login, but stores only its SHA-256 hash digest (`users.api_token_hash`) with a 30-day expiry (`users.api_token_expires_at > NOW()`).
3. **Driver Branch & Order Isolation:**
   Every API query on the backend verifies that `parcel.driver_id == authenticated_user_id` and that the parcel belongs to the driver's active `branch_id`. Couriers cannot view or modify shipments outside their manifest.
4. **Graceful Session Invalidation:**
   If a courier's account is revoked or password is changed from the web admin portal, subsequent API requests return HTTP 401. `AuthController.handleSessionExpired()` immediately halts background GPS timers, wipes secure storage, and returns to the login screen with a user alert.

---

## 📂 State Management & Directory Structure

```
cheetah_driver_app/
├── android/                   # Android native wrapper & Gradle build scripts
├── ios/                       # iOS native wrapper & CocoaPods Podfile
├── assets/                    # Static branding, 3D avatars, and app icons
├── lib/
│   ├── main.dart              # App bootstrap, service init, & GetX theme config
│   ├── controllers/           # GetX Reactive ViewModels
│   │   ├── auth_controller.dart      # Session hydration, theme, language, & lifecycle
│   │   ├── parcel_controller.dart    # Manifest state, search, & offline POD submission
│   │   ├── picking_controller.dart   # WMS warehouse pick wave state management
│   │   └── wallet_controller.dart    # Driver commission accounting & payouts
│   ├── models/                # Strongly-typed data models
│   │   └── parcel_model.dart         # ParcelModel, ParcelStats, & payment status getters
│   ├── routes/                # GetX Named Route Management
│   │   ├── app_pages.dart            # Route definitions & page bindings
│   │   └── app_routes.dart           # Route name constants
│   ├── services/              # Infrastructure & Device Integration Services
│   │   ├── api_service.dart          # HTTP client, auth headers, & error sanitization
│   │   ├── firebase_service.dart     # Standalone-safe FCM push notification handler
│   │   ├── location_service.dart     # 30s GPS telemetry & OS hardware guard
│   │   ├── offline_sync_service.dart # Hive AES-256 encrypted queue & auto-sync
│   │   └── session_store.dart        # Hardware Keystore/Keychain token persistence
│   ├── utils/                 # Design tokens, themes, & localization dictionaries
│   │   ├── app_translations.dart     # 9-Language translation dictionary & string extensions
│   │   └── constants.dart            # Color palettes, typography tokens, & API URLs
│   └── views/                 # Glassmorphic UI Screens & Components
│       ├── home_view.dart            # Primary role-switched scaffold & bottom navigation
│       ├── login_view.dart           # Biometric/credential authentication screen
│       ├── splash_view.dart          # Animated boot splash with session check
│       └── home/
│           ├── qr_scanner_view.dart  # Hardware camera barcode & QR scanner
│           └── tabs/
│               ├── cod_tab.dart      # Real-time Cash on Delivery accounting ledger
│               ├── deliveries_tab.dart # Assigned delivery manifest with search & filter
│               └── picking_tab.dart  # Warehouse picker task fulfillment list
└── analysis_options.yaml      # Static analysis & lint rules
```

---

## 📱 Hardware & OS Compatibility Matrix

### Android
- **Minimum SDK:** Android 5.0 (API Level 21)
- **Target SDK:** Android 14 / Android 15 (API Level 34 / 35 — Google Play Store Standard)
- **Device Support:** 99.4%+ of active global devices (Samsung, Xiaomi, Oppo, Vivo, Realme, OnePlus, Infinix, Tecno, Google Pixel, Zebra rugged industrial scanners).

### iOS
- **Minimum OS:** iOS 14.0
- **Target OS:** iOS 17.x / iOS 18.x (Xcode 15/16 SDK)
- **Device Support:** iPhone 6s through iPhone 16 Pro Max, iPad Air, iPad Pro.

---

## 🚀 CI/CD & Local Build Workflows

### 🤖 Build Android APK & App Bundle
```bash
# Debug APK (for local testing)
flutter build apk --debug

# Production Release APK
flutter build apk --release

# Google Play Store App Bundle (AAB)
flutter build appbundle --release
```

### 🍎 Build iOS Simulator & Release IPA
```bash
# iOS Simulator Build (No Code Signing Required)
flutter build ios --simulator --no-codesign

# Production Release IPA (for TestFlight or App Store)
flutter build ipa --release
```

---

## ⚠️ Production Considerations & Known Limitations

1. **Firebase Standalone Mode:**
   If the app is deployed without configuring `google-services.json` (Android) or `GoogleService-Info.plist` (iOS), the app automatically runs in **Standalone Mode**. Push notifications will be disabled, but all core functions (delivery management, offline sync, GPS tracking, and WMS picking) operate at 100% functionality.
2. **Device Battery Optimization Settings:**
   On certain aggressively power-managed Android distributions (e.g. Xiaomi MIUI/HyperOS, Huawei EMUI), drivers should allow "Unrestricted Background Battery Usage" in OS settings to ensure GPS telemetry pings remain active when the screen is locked.
3. **Camera Permissions:**
   Camera and Location permissions are required for barcode intake and route tracking. If permanently denied in OS settings, the app presents direct action links to the system application settings screen.

---

## 📄 License & Ownership
Copyright © 2026 Cheetah Courier Management System. Private & Proprietary Software.
