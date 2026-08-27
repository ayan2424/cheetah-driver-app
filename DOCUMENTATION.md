# 🛵 Cheetah Driver & Warehouse Picker App — Complete Documentation

> **Version:** 1.0.0+1  
> **Framework:** Flutter 3.x / Dart 3.x  
> **Platform Support:** Android 5.0+ (API 21 to 35) & iOS 14.0+ (iPhone & iPad)  
> **Architecture:** GetX Pattern (MVC-S — Model, View, Controller, Service)  
> **Target Audience:** Codester Buyers, Mobile App Developers, Logistics SaaS Operators  

---

## 📑 Table of Contents

1. [Product Overview](#-product-overview)
2. [Key Features & Highlights](#-key-features--highlights)
3. [Architecture & Folder Structure](#-architecture--folder-structure)
4. [Prerequisites & System Requirements](#-prerequisites--system-requirements)
5. [Step-by-Step Installation & Setup](#-step-by-step-installation--setup)
6. [Configuring API Endpoints](#-configuring-api-endpoints)
7. [App Customization & White-Labeling](#-app-customization--white-labeling)
   - [App Name & Package ID](#app-name--package-id)
   - [Launcher Icons & Splash Screen](#launcher-icons--splash-screen)
   - [Color Palette & Branding](#color-palette--branding)
   - [Adding / Editing Languages](#adding--editing-languages)
8. [Complete REST API Specification](#-complete-rest-api-specification)
   - [Driver API Endpoints](#driver-api-endpoints)
   - [Warehouse Picker API Endpoints](#warehouse-picker-api-endpoints)
9. [Offline-First Sync & Encrypted Hive Queue](#-offline-first-sync--encrypted-hive-queue)
10. [Live GPS Telemetry & Background Location Guard](#-live-gps-telemetry--background-location-guard)
11. [Building & Publishing for Production](#-building--publishing-for-production)
    - [Android: Release APK & Google Play App Bundle (.aab)](#android-release-apk--app-bundle)
    - [iOS: Release IPA & App Store Submission](#ios-release-ipa--app-store-submission)
12. [Troubleshooting & Common Questions (FAQ)](#-troubleshooting--common-questions-faq)
13. [Support, Updates & Licensing](#-support-updates--licensing)

---

## 🌟 Product Overview

The **Cheetah Driver & Warehouse Picker App** is a high-performance, production-grade cross-platform mobile application designed specifically for modern logistics, express couriers, 3PL providers, and e-commerce fulfillment centers.

It offers a **dual-role dynamic interface**:
1. **Courier Drivers / Riders:** Manage assigned parcel deliveries and pickups, capture digital customer signatures, take photo proof of delivery (POD), verify delivery OTPs, reconcile Cash on Delivery (COD) balances, and transmit real-time GPS telemetry to the admin dispatch map.
2. **WMS Warehouse Pickers:** Receive real-time pick tasks dispatched from the Warehouse Management System, locate items across warehouse zones, aisles, and shelves, and verify SKU barcodes using high-speed camera scanning.

Built with Flutter 3.x and Dart 3.x, the application delivers smooth 60/120 FPS performance, AES-encrypted offline data persistence, instant camera-based barcode scanning, and multi-language internationalization.

---

## ⚡ Key Features & Highlights

### 🛵 Courier Driver Portal
- **Smart Delivery Dashboard:** View assigned, out-for-delivery, delivered, failed, and picked-up parcels with real-time status counters.
- **Turn-by-Turn Navigation:** One-tap integration with Google Maps, Apple Maps, and Waze directly from parcel destination addresses.
- **Direct Phone Dialing:** Contact senders and recipients with a single tap.
- **Proof of Delivery (POD) Suite:**
  - Responsive smooth digital signature canvas with base64/PNG export.
  - Camera capture and gallery photo upload for package drop-off verification.
  - Delivery OTP verification support.
  - Receiver name and handover note logging.
- **Cash on Delivery (COD) Ledger & Wallet:** Real-time calculation of collected cash, pending branch vault deposits, and historical settlement logs.
- **Offline Delivery Mode:** Record PODs and status updates without an active internet connection; the app automatically queues and syncs them once connectivity is restored.

### 🏭 Warehouse Picker Portal
- **Real-Time WMS Task Queue:** Instant task synchronization for picking sales orders and fulfillment batches.
- **Precise Shelf Routing:** Clear visual hierarchy of Warehouse Zone → Aisle → Rack → Shelf → Bin.
- **High-Speed Barcode & QR Scanner:** Camera-based hardware scanner powered by `mobile_scanner` with haptic feedback and torch toggle.
- **Task Status Pipeline:** Seamlessly update picking tasks (`In Progress`, `Completed`, `Issue / Out of Stock`).

### 🛡️ Enterprise Security & Telemetry
- **Hardware GPS Guard:** Background and foreground GPS enforcement that notifies the dispatch dashboard if location services are toggled off.
- **Encrypted Local Storage:** AES-encrypted Hive boxes for offline queueing, ensuring no sensitive customer or delivery data is exposed in plaintext.
- **JWT / Bearer Token Authentication:** Secure session management with `flutter_secure_storage`.
- **Light & Dark Theme Engine:** Premium glassmorphic interface with system auto-detection and manual toggle.
- **Multi-Language Support:** Pre-configured with English, Spanish, Arabic (RTL support), French, German, Hindi, Urdu, Portuguese, Russian, and Chinese.

---

## 🏗 Architecture & Folder Structure

The project follows a clean, modular **GetX (MVC-S)** architecture for state management, dependency injection, and micro-routing:

```text
cheetah_driver_app/
├── android/                    # Android Native Gradle Project (API 21-35)
├── ios/                        # iOS Native Xcode Workspace (iOS 14.0+)
├── assets/                     # App Images, Icons, and Audio
│   ├── icons/                  # SVG and PNG Icons
│   └── images/                 # App Logos and Illustrations
├── lib/
│   ├── controllers/            # GetX Reactive Business Logic Controllers
│   │   ├── auth_controller.dart       # User authentication, session, & profile state
│   │   ├── parcel_controller.dart     # Parcels list, filters, & POD upload
│   │   ├── picking_controller.dart    # Warehouse pick tasks & barcode verification
│   │   └── wallet_controller.dart     # Driver COD balance & wallet statistics
│   ├── models/                 # Data Models with JSON Serialization
│   │   └── parcel_model.dart          # Parcel, Stats, and PickTask data entities
│   ├── routes/                 # Navigation & Route Definitions
│   │   └── app_pages.dart             # GetPage route configurations & bindings
│   ├── services/               # Hardware & Backend Integration Services
│   │   ├── api_service.dart           # HTTP Client & REST API endpoints
│   │   ├── location_service.dart      # Real-time GPS tracking & telemetry guard
│   │   ├── offline_sync_service.dart  # AES-encrypted Hive offline queue & sync
│   │   ├── permission_service.dart    # Camera & location OS permission handling
│   │   └── session_store.dart         # Secure credential storage
│   ├── utils/                  # App Constants, Colors, & Translations
│   │   ├── app_translations.dart      # 10+ Language translations map
│   │   └── constants.dart             # API Base URLs, Color palettes, & Routes
│   ├── views/                  # UI Screens & Component Widgets
│   │   ├── home/
│   │   │   ├── qr_scanner_view.dart   # Camera barcode/QR scanning view
│   │   │   └── tabs/
│   │   │       ├── cod_tab.dart       # COD ledger & wallet summary
│   │   │       ├── deliveries_tab.dart# Assigned deliveries & POD triggers
│   │   │       └── picking_tab.dart   # WMS warehouse picking interface
│   │   ├── home_view.dart             # Main scaffold with bottom navigation bar
│   │   ├── login_view.dart            # Driver & Picker login screen
│   │   └── splash_view.dart           # Animated splash screen
│   └── main.dart               # App entrypoint, Theme configuration, & Init
├── pubspec.yaml                # Flutter Dependencies & Asset declarations
└── README.md                   # Quick repository overview
```

---

## 💻 Prerequisites & System Requirements

Before setting up the project, ensure your development workstation meets the following requirements:

| Tool / Dependency | Minimum Version | Recommended Version |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.12.0` | `3.24.x` or latest stable |
| **Dart SDK** | `3.0.0` | `3.5.x` |
| **Android Studio** | Hedgehog (2023.1) | Ladybug (2024.2+) |
| **Java Development Kit (JDK)** | OpenJDK 17 | OpenJDK 17 (bundled with Android Studio) |
| **Android SDK Tools** | API Level 21 (Android 5.0) | API Level 34 / 35 (Android 14 / 15) |
| **Xcode (for iOS)** | Xcode 14.3 | Xcode 15.4 / 16.x (macOS Sonoma / Sequoia) |
| **CocoaPods (for iOS)** | `1.12.0` | `1.15.2` or latest |

---

## 🚀 Step-by-Step Installation & Setup

### 1. Extract & Open Project
Extract the downloaded package and open the `cheetah_driver_app` folder in **Visual Studio Code** or **Android Studio**.

### 2. Install Flutter Dependencies
Open a terminal inside the project directory and execute:
```bash
flutter pub get
```

### 3. Verify Environment Readiness
Run Flutter doctor to check if all platform SDKs and toolchains are properly configured:
```bash
flutter doctor -v
```

### 4. Run on Connected Device or Simulator
- **Android Device / Emulator:**
  ```bash
  flutter run
  ```
- **iOS Simulator (macOS):**
  ```bash
  cd ios && pod install --repo-update && cd ..
  flutter run
  ```

---

## 🌐 Configuring API Endpoints

All network communication with the Cheetah Courier Backend is configured in a single configuration file:  
`lib/utils/constants.dart`

```dart
class AppConstants {
  // Replace with your live domain (Must include trailing slash and HTTPS)
  static const String baseUrl = 'https://your-domain.com/';
  
  // Driver and Picker REST API endpoints
  static const String apiUrl = '${baseUrl}api/v1/driver/';
  static const String pickerApiUrl = '${baseUrl}api/v1/picker/';
}
```

> **Important:** Ensure that your backend domain uses a valid SSL certificate (`https://`). Android and iOS block unencrypted `http://` traffic by default unless cleartext traffic is explicitly permitted.

---

## 🎨 App Customization & White-Labeling

### App Name & Package ID

#### 1. Android App Name & Package ID
- **App Name:** Open `android/app/src/main/AndroidManifest.xml` and update:
  ```xml
  <application
      android:label="Your Brand Driver"
      ...>
  ```
- **Package ID (Application ID):** Open `android/app/build.gradle` and change:
  ```groovy
  defaultConfig {
      applicationId "com.yourcompany.cheetahdriver"
      minSdkVersion 21
      targetSdkVersion 34
      versionCode 1
      versionName "1.0.0"
  }
  ```

#### 2. iOS App Name & Bundle Identifier
- **App Name:** Open `ios/Runner/Info.plist` and update:
  ```xml
  <key>CFBundleDisplayName</key>
  <string>Your Brand Driver</string>
  ```
- **Bundle ID:** Open the `ios/` directory in Xcode, select the **Runner** project in the left navigator, and update the **Bundle Identifier** under **Signing & Capabilities** (e.g., `com.yourcompany.cheetahdriver`).

---

### Launcher Icons & Splash Screen

The project uses `flutter_launcher_icons` for automated high-resolution app icon generation across all Android mipmap and iOS Assets densities.

1. Place your 1024x1024 PNG logo at `assets/images/app_icon.png`.
2. Configure `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: "launcher_icon"
     ios: true
     image_path: "assets/images/app_icon.png"
     min_sdk_android: 21
     adaptive_icon_background: "#09090b"
     adaptive_icon_foreground: "assets/images/app_icon.png"
   ```
3. Run the generator command:
   ```bash
   dart run flutter_launcher_icons
   ```

---

### Color Palette & Branding

Modify the primary brand colors in `lib/utils/constants.dart`:

```dart
class AppColors {
  // Dark Theme Palette
  static const Color background = Color(0xFF09090b);
  static const Color cardBg = Color(0xFF121216);
  static const Color primary = Color(0xFFFF4D00);      // Brand Orange
  static const Color primaryLight = Color(0xFFFF7700);
  static const Color accentGreen = Color(0xFF10b981);   // Success / Delivered
  static const Color accentBlue = Color(0xFF3b82f6);    // In-Transit
  static const Color accentGold = Color(0xFFf59e0b);    // COD / Pending
}

class AppColorsLight {
  // Light Theme Palette
  static const Color background = Color(0xFFf4f4f6);
  static const Color cardBg = Color(0xFFffffff);
  static const Color primary = Color(0xFFFF4D00);
  static const Color accentGreen = Color(0xFF059669);
}
```

---

### Adding / Editing Languages

The app includes full multi-language localization via `lib/utils/app_translations.dart`. To add or modify translations:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'app_title': 'Cheetah Driver',
      'assigned_parcels': 'Assigned Parcels',
      'complete_delivery': 'Complete Delivery',
      'collect_cod': 'Collect COD Amount',
      // Add custom keys here...
    },
    'es_ES': {
      'app_title': 'Conductor Cheetah',
      'assigned_parcels': 'Paquetes Asignados',
      'complete_delivery': 'Completar Entrega',
      'collect_cod': 'Cobrar Contra Reembolso',
    },
    // Supports Arabic (ar_SA), French (fr_FR), German (de_DE), etc.
  };
}
```

Switch languages dynamically anywhere in the app with:
```dart
Get.updateLocale(const Locale('es', 'ES'));
```

---

## 📡 Complete REST API Specification

All endpoints communicate via HTTPS and accept either `POST (Form-Data / x-www-form-urlencoded)` or `JSON`. Authenticated requests require the HTTP header:
```http
Authorization: Bearer <JWT_USER_TOKEN>
Accept: application/json
```

---

### Driver API Endpoints

#### 1. Driver Login
- **Endpoint:** `POST /api/v1/driver/login.php`
- **Authentication:** Public
- **Request Body:**
  ```json
  {
    "email": "driver@example.com",
    "password": "Password123"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
    "driver": {
      "id": 14,
      "name": "Ahmed Ali",
      "email": "driver@example.com",
      "phone": "+971501234567",
      "role": "driver",
      "branch_id": 2,
      "vehicle_type": "Motorcycle",
      "license_plate": "DXB-8821",
      "avatar": "https://your-domain.com/uploads/drivers/avatar_14.jpg"
    }
  }
  ```

---

#### 2. Get Assigned Parcels & Statistics
- **Endpoint:** `POST /api/v1/driver/get_parcels.php`
- **Authentication:** `Bearer <TOKEN>`
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "stats": {
      "total": 18,
      "pending": 6,
      "delivered": 11,
      "returned": 1,
      "cod_total": 2450.00
    },
    "parcels": [
      {
        "id": 1082,
        "tracking_number": "CH-89217340",
        "sender_name": "Dubai Electronics Hub",
        "sender_phone": "+97142211990",
        "sender_address": "Deira Port Saeed, Dubai",
        "receiver_name": "Sarah Connor",
        "receiver_phone": "+971509876543",
        "receiver_address": "Villa 42, Al Barsha 2, Dubai",
        "latitude": 25.1124,
        "longitude": 55.2018,
        "cod_amount": 350.00,
        "weight_kg": 2.5,
        "status": "Out for Delivery",
        "created_at": "2026-08-26 14:30:00",
        "special_instructions": "Call upon arrival. Ring gate bell."
      }
    ]
  }
  ```

---

#### 3. Update Status & Submit Proof of Delivery (POD)
- **Endpoint:** `POST /api/v1/driver/update_status.php`
- **Content-Type:** `multipart/form-data`
- **Authentication:** `Bearer <TOKEN>`
- **Fields:**
  | Field Name | Type | Required | Description |
  | :--- | :--- | :--- | :--- |
  | `parcel_id` | Integer | Yes | Unique parcel database ID |
  | `tracking_number` | String | Yes | Tracking reference code |
  | `status` | String | Yes | `Delivered`, `Failed`, `Out for Delivery`, `Picked Up` |
  | `receiver_name` | String | Yes | Name of individual receiving item |
  | `description` | String | No | Notes, handover remarks, or failure reason |
  | `delivery_otp` | String | No | Customer OTP verification code (if enabled) |
  | `signature` | Binary / File | No | Captured signature image (PNG) |
  | `photo` | Binary / File | No | Camera photo proof of delivery |

- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Parcel status and Proof of Delivery submitted successfully.",
    "parcel_id": 1082,
    "new_status": "Delivered"
  }
  ```

---

#### 4. Transmit Live GPS Telemetry
- **Endpoint:** `POST /api/v1/driver/update_location.php`
- **Authentication:** `Bearer <TOKEN>`
- **Request Body:**
  ```json
  {
    "latitude": 25.112450,
    "longitude": 55.201820,
    "gps_enabled": 1
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Location ping synchronized."
  }
  ```

---

#### 5. Driver COD Ledger & Wallet
- **Endpoint:** `POST /api/v1/driver/get_wallet.php`
- **Authentication:** `Bearer <TOKEN>`
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "wallet": {
      "total_collected": 5400.00,
      "pending_settlement": 1250.00,
      "settled_to_vault": 4150.00,
      "currency": "AED",
      "recent_transactions": [
        {
          "id": 94,
          "tracking_number": "CH-89217340",
          "amount": 350.00,
          "type": "COD Collection",
          "status": "In Driver Pocket",
          "date": "2026-08-26 16:10:00"
        }
      ]
    }
  }
  ```

---

### Warehouse Picker API Endpoints

#### 1. Fetch Assigned Pick Tasks
- **Endpoint:** `POST /api/v1/picker/wms_get_pick_tasks.php`
- **Authentication:** `Bearer <TOKEN>`
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "tasks": [
      {
        "task_id": 402,
        "order_number": "ORD-2026-9901",
        "product_name": "Wireless Noise-Cancelling Headphones",
        "sku": "TECH-HD-001",
        "barcode": "8901234567890",
        "quantity_to_pick": 2,
        "quantity_picked": 0,
        "location": {
          "zone": "Zone A",
          "aisle": "Aisle 04",
          "rack": "Rack 12",
          "shelf": "Shelf B",
          "bin": "Bin 03"
        },
        "status": "pending"
      }
    ]
  }
  ```

---

#### 2. Update Pick Task Status / Confirm Barcode Scan
- **Endpoint:** `POST /api/v1/picker/wms_update_task.php`
- **Content-Type:** `application/json`
- **Authentication:** `Bearer <TOKEN>`
- **Request Body:**
  ```json
  {
    "task_id": 402,
    "status": "completed"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Pick task marked as completed."
  }
  ```

---

## 🔒 Offline-First Sync & Encrypted Hive Queue

The application is architected to operate flawlessly in areas with poor or zero network coverage (e.g., building basements, underground parking, remote delivery zones).

### How Offline Mode Works:
1. **Network Connectivity Detection:** The app listens to the OS connectivity stream (`connectivity_plus`).
2. **Encrypted Queueing:** When a driver completes a delivery offline, the entire POD payload (signature binary, photos, coordinates, and notes) is encrypted using **AES-256** and saved into a local Hive Box (`offline_pod_queue`).
3. **Automatic Background Sync:** As soon as 4G/5G/Wi-Fi is re-established, the `OfflineSyncService` sequentially executes pending uploads, sends them to `update_status.php`, and removes successfully synchronized jobs from disk.

---

## 🛰️ Live GPS Telemetry & Background Location Guard

To prevent fraud and maintain dispatch visibility, the app includes a **hardware-level location enforcement guard**:
- Listens to real-time OS hardware stream `Geolocator.getServiceStatusStream()`.
- If a rider disables location services or GPS hardware, the app immediately transmits a `gps_enabled: 0` event to the dispatch server and presents a non-dismissible modal prompting the rider to enable GPS.
- Upon re-enabling, coordinates are synchronized and the modal automatically dismisses.

---

## 📦 Building & Publishing for Production

### Android: Release APK & App Bundle

#### 1. Generate an Upload Keystore
Generate a private signing key using the Java `keytool` utility:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### 2. Configure `android/key.properties`
Create `android/key.properties` (do not commit this file to public git repos):
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

#### 3. Build Commands
- **Google Play Store (.aab bundle):**
  ```bash
  flutter build appbundle --release
  ```
  *Output:* `build/app/outputs/bundle/release/app-release.aab`

- **Standalone Universal APK (.apk):**
  ```bash
  flutter build apk --release
  ```
  *Output:* `build/app/outputs/flutter-apk/app-release.apk`

---

### iOS: Release IPA & App Store Submission

#### 1. Configure Signing in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Under **Signing & Capabilities**, select your **Apple Developer Team**.
3. Ensure the Bundle Identifier is registered in your Apple Developer account.

#### 2. Build Commands
```bash
# Clean and install pods
cd ios
pod install --repo-update
cd ..

# Build release IPA
flutter build ipa --release
```
*Output:* `build/ios/archive/Runner.xcarchive` & `build/ios/ipa/`

Upload the generated `.ipa` to Apple TestFlight or App Store Connect using Xcode Organizer or Transporter.

---

## ❓ Troubleshooting & Common Questions (FAQ)

### Q1: `CocoaPods could not find compatible versions for pod ...`
**Solution:** Run the following commands to refresh CocoaPods repositories:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
cd ..
```

### Q2: Android Gradle build fails with `minSdkVersion` error
**Solution:** The app requires a minimum SDK of **API 21** (Android 5.0). Ensure `android/app/build.gradle` defines:
```groovy
minSdkVersion 21
```

### Q3: Camera / Barcode scanner shows black screen on simulator
**Solution:** Hardware camera scanning requires physical camera sensors. Always test barcode scanning and POD photo capture on a physical Android or iOS device.

### Q4: Network requests fail with `SocketException: OS Error: Connection refused`
**Solution:** 
- If testing on local development server, use your computer's local LAN IP (e.g., `https://192.168.1.50/`) instead of `localhost` or `127.0.0.1`.
- Ensure your backend web server SSL certificate is trusted.

---

## 📄 Support, Updates & Licensing

- **Product Ownership:** Cheetah Courier Management System Mobile Suite
- **Marketplace Listing:** Codester / Private Commercial License
- **Technical Support:** For questions, custom API integrations, or feature requests, contact your author via your Codester customer dashboard or email support.
- **Copyright:** © 2026 Cheetah Logistics SaaS. All Rights Reserved.
