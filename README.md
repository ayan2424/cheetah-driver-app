# 🛵 Cheetah Driver & Picker Mobile App

[![Flutter Build](https://github.com/ayan2424/cheetah-driver-app/actions/workflows/ios-simulator-build.yml/badge.svg)](https://github.com/ayan2424/cheetah-driver-app/actions/workflows/ios-simulator-build.yml)
[![Flutter SDK](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![iOS Target](https://img.shields.io/badge/iOS-14.0%2B-lightgrey.svg)](https://apple.com/ios)
[![Android Target](https://img.shields.io/badge/Android-5.0%2B%20(API%2021%2B)-green.svg)](https://android.com)

Production-grade cross-platform mobile application for **Cheetah Courier Management System (Cheetah WMS)** designed specifically for **Drivers/Riders** (pickup, parcel delivery, live GPS tracking, signature & COD collection) and **Warehouse Pickers** (shelf barcode scanning, batch order picking).

---

## 📱 OS & Device Compatibility Matrix

### 1. Android (Smartphones & Rugged Handheld Scanners)
- **Minimum Supported OS:** Android 5.0 (Lollipop) / 6.0 (Marshmallow) — **API Level 21+ / 23+**
- **Target OS Version:** Android 14 / Android 15 (**API Level 34 / 35** — Latest Play Store Standard)
- **Global Coverage:** 99.4%+ of active Android devices worldwide (Samsung, Xiaomi, Oppo, Vivo, Realme, OnePlus, Infinix, Tecno, Google Pixel, Zebra handhelds).

### 2. iOS (iPhone & iPad)
- **Minimum Supported OS:** **iOS 14.0**
- **Target OS Version:** **iOS 17.x / iOS 18.x** (Xcode 15/16 SDK)
- **Supported iPhones:** iPhone 6s, 7, 8, X, XS, XR, 11, 12, 13, 14, 15, 16 Series & iPadOS 14.0+.

---

## 🛠️ Technical Stack & Architecture

- **Framework:** Flutter 3.x (Dart 3.x)
- **State Management & Routing:** GetX (`get: ^4.6.6`)
- **Offline Storage & Caching:** Hive (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`) & GetStorage
- **Barcode & QR Scanning:** Mobile Scanner (`mobile_scanner: ^5.2.3`)
- **Live GPS & Location:** Geolocator (`geolocator: ^12.0.0`)
- **Permissions Management:** Permission Handler (`permission_handler: ^11.3.1`)
- **Customer Signatures:** Signature (`signature: ^5.4.0`)
- **Network & API:** HTTP (`http: ^1.1.0`) with Flutter Secure Storage (`flutter_secure_storage: ^10.3.1`)

---

## 🚀 CI/CD & Build Workflows

### GitHub Actions (`.github/workflows/ios-simulator-build.yml`)
- Automated iOS Simulator `.app` & `.ipa` release builds.
- CocoaPods dependency caching & repo synchronization (`pod install --repo-update`).
- Pre-configured deployment target (`platform :ios, '14.0'`).

### Local Build Commands

#### 🤖 Build Android APK & App Bundle
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Google Play
flutter build appbundle --release
```

#### 🍎 Build iOS Simulator & Release IPA
```bash
# iOS Simulator
flutter build ios --simulator --no-codesign

# Release IPA (for TestFlight or App Store)
flutter build ipa --release
```

---

## 🔐 Role Access Control & Features

1. **Driver Role:**
   - View assigned delivery routes & pending pickups.
   - Live turn-by-turn navigation & recipient call integration.
   - Proof of Delivery (POD) signature capture & camera photo upload.
   - Real-time Cash on Delivery (COD) collection ledger.

2. **Picker Role:**
   - Real-time pick tasks assigned by Warehouse Manager.
   - Shelf location guidance (Zone → Aisle → Shelf).
   - Barcode scanning to confirm correct SKU item selection.

---

## 📄 License & Ownership
Copyright © 2026 Cheetah Courier Management System. Private & Proprietary Software.
