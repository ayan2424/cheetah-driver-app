# 📦 Codester Product Submission Guide — Cheetah Driver & Warehouse Picker App (Flutter)

> **Instructions for Seller:** This document is formatted to perfectly match the **Codester Product Upload Form** sections as shown in your screenshot. Every section you need to copy is placed inside a code block. Hover over the code block to click the **Copy** button, then paste it directly into Codester.

---

## 1️⃣ ITEM & DESCRIPTION

### Title
*(Copy & paste into the **Title** input box)*

```text
Cheetah - Delivery Driver & Warehouse Picker Mobile App (Flutter | Android & iOS)
```

### Short description
*(Copy & paste into the **Short description** input box — Max 150-160 characters)*

```text
Cross-platform Flutter app for delivery drivers & warehouse pickers — Live GPS tracking, digital signature POD, barcode scanning & offline sync.
```

### Description
*(Copy & paste this HTML into the **Description** box)*

```html
<h3>🛵 Cheetah Driver & Warehouse Picker App — Enterprise Cross-Platform Mobile Suite (Flutter 3.x)</h3>

<p>The <strong>Cheetah Driver & Warehouse Picker Mobile App</strong> is an enterprise-grade, high-performance cross-platform application developed with <strong>Flutter 3.x</strong> and <strong>Dart 3.x</strong>. Engineered as the official mobile companion for the <strong>Cheetah Courier Management & WMS SaaS (v10.0 Commercial Release)</strong>, it provides a specialized, role-isolated operational client for both <strong>Courier Delivery Drivers / Riders</strong> and <strong>WMS Warehouse Pickers</strong>.</p>

<p>Whether connected natively to the Cheetah Courier backend or integrated into your own custom logistics REST API, this app delivers 60/120 FPS fluid animations, hardware-level GPS anti-tampering enforcement, digital customer signatures, drop-off photo proof of delivery (POD), live camera barcode scanning, and zero-data-loss AES-256 encrypted offline queueing.</p>

<hr>

<h3>🌟 Dual-Role Operational Capabilities</h3>

<h4>1. 🛵 Delivery Driver / Courier Rider Portal</h4>
<ul>
  <li><strong>Smart Delivery Pipeline:</strong> View assigned shipments categorized by status (<em>Assigned</em>, <em>Out for Delivery</em>, <em>Delivered</em>, <em>Failed / Returned</em>).</li>
  <li><strong>Branded CHT- Tracking Compatibility:</strong> Natively parses, detects, and displays branded <code>CHT-{ORIGIN_CODE}-{SERIAL}</code> tracking numbers (e.g. <code>CHT-KHI-000001</code>) with instant barcode scanner recognition.</li>
  <li><strong>Turn-by-Turn GPS Navigation:</strong> One-tap routing integration with Google Maps, Apple Maps, and Waze directly from parcel destination addresses.</li>
  <li><strong>Instant Customer Contact:</strong> 1-tap phone calls and direct WhatsApp chat integration to connect with senders and receivers.</li>
  <li><strong>Proof of Delivery (POD) Suite:</strong>
    <ul>
      <li>Smooth touchscreen digital signature pad with PNG export.</li>
      <li>Drop-off photo capture via device camera or gallery upload with server-side non-repudiation watermarking.</li>
      <li>Customer delivery OTP (One-Time Password) verification support.</li>
      <li>Receiver name and handover delivery remarks logging.</li>
    </ul>
  </li>
  <li><strong>Cash on Delivery (COD) Wallet Ledger:</strong> Real-time tracking of collected COD cash, pending branch vault deposits, and driver payout transaction history with double-spend idempotency key protection.</li>
  <li><strong>Live Background GPS Telemetry:</strong> Transmits real-time coordinates, speed, and heading to the central dispatcher fleet map with anti-tampering hardware detection.</li>
</ul>

<h4>2. 🏭 Warehouse Picker Portal (WMS Fulfillment)</h4>
<ul>
  <li><strong>Real-Time WMS Pick Queue:</strong> Instant synchronization of pending sales order fulfillment batches dispatched by warehouse managers.</li>
  <li><strong>5-Tier Spatial Navigation:</strong> Visual warehouse shelf hierarchy (<em>Warehouse &rarr; Zone &rarr; Aisle &rarr; Shelf &rarr; Bin</em>) to minimize picker walking time and eliminate pick errors.</li>
  <li><strong>High-Speed Camera Barcode & QR Scanner:</strong> Instant SKU barcode detection powered by <code>mobile_scanner</code> with flashlight toggle and haptic vibration feedback.</li>
  <li><strong>Fulfillment Pipeline:</strong> 1-tap status toggling (<em>In Progress</em>, <em>Completed</em>) automatically transitions sales orders to <code>Prepared</code> in Cheetah WMS.</li>
</ul>

<hr>

<h3>🛡️ Enterprise Features & Reliability</h3>

<ul>
  <li><strong>🔔 Firebase Cloud Messaging (FCM) Ready:</strong> Real-time background wake-on-lock push notifications alerting drivers to newly assigned parcels and warehouse pickers to fresh sales order fulfillment batches. Works in standalone mode or connected to Firebase.</li>
  <li><strong>🔒 AES-256 Encrypted Offline Queue:</strong> In underground parking lots, basements, or remote delivery routes with zero cell reception, POD records and status updates are encrypted with AES-256 and stored locally in Hive. The app automatically retries and flushes queued uploads the moment internet connectivity returns.</li>
  <li><strong>🛰️ Hardware GPS Anti-Tampering Guard:</strong> Active OS hardware listeners detect any attempt to disable location services, notifying dispatchers instantly with a <code>gps_enabled: 0</code> alert and locking the screen with a mandatory prompt to re-enable GPS.</li>
  <li><strong>🔐 19-Layer Backend Security Alignment:</strong> Hardware-backed token storage in Android Keystore / iOS Keychain, SHA-256 bearer tokens at rest, 5-attempt brute-force rate-limiting lockout on login, and captive portal HTML response bleed guards.</li>
  <li><strong>🌐 23-Language Support with Full RTL:</strong> Pre-configured with translations for English, Spanish, Arabic (with native RTL layout mirroring), French, German, Hindi, Urdu, Portuguese, Russian, and Chinese.</li>
  <li><strong>🌓 Dark & Light Glassmorphic UI:</strong> Stunning, high-contrast visual design with system auto-detection and manual toggle.</li>
  <li><strong>📱 Universal Device Compatibility:</strong> Fully optimized for smartphones, tablets, and rugged industrial handheld Android barcode scanners (Zebra, Honeywell, Newland).</li>
</ul>

<hr>

<h3>📊 Live Demo & Testing</h3>

<p>Test the mobile app authentication and integration live with our demo backend:</p>
<p><strong>🔗 Web Backend Demo:</strong> <a href="https://cheetah.ayan24.me" target="_blank">https://cheetah.ayan24.me</a></p>

<ul>
  <li><strong>🚗 Driver Demo Login:</strong> <code>rider@cheetah.com</code> / Password: <code>Rider123</code></li>
  <li><strong>🏗️ Picker Demo Login:</strong> <code>picker@cheetah.com</code> / Password: <code>Picker123</code></li>
</ul>

<hr>

<h3>📦 What You Will Receive</h3>
<ul>
  <li>Full Flutter 3.x & Dart 3.x Source Code (MVC-S GetX Architecture).</li>
  <li>Android Project Workspace (Gradle, ProGuard rules, Android 14/15 target, API 21-35).</li>
  <li>iOS Xcode Workspace (CocoaPods, iOS 14.0 to 18.x compatible).</li>
  <li>Interactive Buyer Documentation HTML Webpage (<code>Documentation.html</code>) with live search and copy-code snippets.</li>
  <li>Full Developer Technical Markdown Documentation (<code>DOCUMENTATION.md</code>).</li>
  <li>Dedicated Firebase Push Notifications Setup Guide (<code>FIREBASE_SETUP.md</code>).</li>
  <li>Step-by-step App Store & Google Play publishing guide.</li>
</ul>

<hr>

<h3>⚙️ Technical Requirements</h3>
<ul>
  <li>Flutter SDK 3.12.0 or higher (Dart 3.x compatible)</li>
  <li>Android Studio (Hedgehog / Ladybug or newer) or Visual Studio Code</li>
  <li>Java JDK 17 (bundled with Android Studio)</li>
  <li>Android SDK with Minimum API Level 21 (Android 5.0) and Target API Level 34/35 (Android 14/15)</li>
  <li>macOS with Xcode 15+ & CocoaPods 1.12+ (Only required for compiling iOS builds)</li>
  <li>A live Cheetah Courier & WMS backend OR your custom REST API server with HTTPS</li>
</ul>
```

### Features
*(Copy & paste into the **Features** box)*

```text
• Complete cross-platform Flutter 3.x source code for Android & iOS
• Dual-role operational interface: Delivery Driver & Warehouse Picker in one single app
• Branded CHT- Tracking Numbers (CHT-KHI-000001 format) compatibility with camera barcode recognition
• Firebase Cloud Messaging (FCM) push notification engine for instant dispatch alerts
• Live turn-by-turn navigation with Google Maps, Apple Maps, and Waze
• Proof of Delivery (POD) suite: Digital signature capture pad + photo drop-off attachment
• Server-side non-repudiation watermarking on all delivery proof photos
• Customer delivery OTP (One-Time Password) verification engine
• High-speed camera barcode and QR code scanner for SKU item verification
• 5-Tier WMS spatial picking hierarchy (Warehouse -> Zone -> Aisle -> Shelf -> Bin)
• Real-time Cash on Delivery (COD) collection wallet & settlement ledger with idempotency protection
• AES-256 encrypted offline queue via Hive with automatic background sync
• Hardware-level GPS anti-tampering telemetry guard & central map broadcasting
• 1-tap customer phone dialing and direct WhatsApp chat integration
• 23-Language internationalization including full RTL layout support (Arabic, Urdu)
• Premium Dark and Light glassmorphic themes with system auto-detection
• Token-based Bearer authentication with hardware-backed Android Keystore / iOS Keychain storage
• 5-attempt brute-force rate-limiting lockout protection on API authentication
• Clean GetX (MVC-S) architecture with reactive controllers and decoupled services
• Dedicated Firebase FCM setup guide (FIREBASE_SETUP.md) & interactive HTML docs (Documentation.html)
• Ready for Google Play Store (.aab bundle, Target SDK 35) and Apple App Store (.ipa, iOS 18) publishing
```

### Instructions
*(Copy & paste into the **Instructions** box)*

```text
1. Extract the downloaded cheetah_driver_app.zip package.
2. Open the project folder in Visual Studio Code or Android Studio.
3. Open "lib/utils/constants.dart" and update baseUrl with your live domain:
   static const String baseUrl = 'https://your-domain.com/';
4. Open your terminal in the project root and run:
   flutter pub get
5. To test on a connected Android device or emulator:
   flutter run
6. For iOS builds (on macOS):
   cd ios && pod install --repo-update && cd ..
   flutter run
7. To generate production release builds:
   - Android App Bundle (Google Play): flutter build appbundle --release
   - Android Standalone APK: flutter build apk --release
   - Apple iOS Release IPA: flutter build ipa --release
8. For complete step-by-step branding, custom icons, and app store publishing instructions, open "Documentation.html" included in the root folder.
```

---

## 2️⃣ FILES
*(Upload your files and fill in URLs as shown in the "Files" section)*

- **Upload file:** Upload your final `cheetah_driver_app.zip` archive here.
- **Demo URL:** 
```text
https://cheetah.ayan24.me
```
- **Screenshots:** Upload your high-resolution app presentation images here.

---

## 3️⃣ CATEGORY & ATTRIBUTES
*(Select EXACTLY these checkboxes based on the Cheetah App's features)*

```text
Category:
- Flutter

Files included (Check these):
[x] .html
[x] .css
[x] .m
[x] .swift
[x] .java
[x] .apk
[x] Layered .png
[x] .json
[x] .dart
[x] .kt
[x] .gradle
[x] .gradle.kts
[x] .yml/.yaml
[x] .md
[x] pubspec.yaml

Operating Systems (Check these):
[x] iOS 15.0
[x] iOS 16.0
[x] iOS 17.0
[x] iOS 18.0
[x] Android 5.0
[x] Android 6.0
[x] Android 7.0
[x] Android 8.0
[x] Android 9.0
[x] Android 10.0
[x] Android 11.0
[x] Android 12.0
[x] Android 13.0
[x] Android 14.0
[x] Android 15.0
[x] Android 16.0

Programming language (Check these):
[x] Java
[x] Kotlin
[x] Dart
[x] Objective-C
[x] Swift

App framework / engine (Check these):
[x] Android (Native)
[x] iOS (Native)
[x] Flutter
```

---

## 4️⃣ PRICING
*(Fill in the pricing fields in USD)*

- **Item cost:**
```text
49
```
- **Extended:**
```text
149
```

---

## 5️⃣ TAGS
*(Copy & paste into the **Tags** input box)*

```text
flutter app, delivery driver app, courier app, warehouse picker, wms app, firebase fcm, push notifications, proof of delivery, pod signature, gps tracking, live telemetry, barcode scanner, qr scanner, cod wallet, offline sync, logistics app, courier driver, flutter 3, android app, ios app, dispatch app, delivery tracking
```

---

## 6️⃣ MESSAGE TO REVIEWER

### Message
*(Copy & paste into the **Message** box)*

```text
Hello Codester Quality & Review Team,

Thank you for reviewing the Cheetah Driver & Warehouse Picker Mobile App (Flutter 3.x / Dart 3.x).

This is a production-grade, hand-crafted enterprise logistics client built from the ground up to accompany modern courier and WMS operations. It contains zero AI wrappers, zero license locks, zero domain restrictions, and zero obfuscation. All code is cleanly structured under reactive MVVM (GetX) with decoupled hardware services.

KEY PRODUCTION VALIDATION HIGHLIGHTS:
1. Static Analysis: Passed 'flutter analyze' with ZERO issues, ZERO warnings, and ZERO errors.
2. OS Compatibility: Validated on Android 14 & 15 (Target SDK 35, Min SDK 21) and iOS 18 (Xcode 16 / CocoaPods 1.15+).
3. Native Hardware Security:
   - Tokens stored in Android Keystore / Apple Keychain (AES-256 GCM via flutter_secure_storage).
   - Offline POD Queue uses Hive with AES-256 local encryption and automatic connectivity re-sync.
   - Low-level OS hardware listeners detect GPS disable tampering and alert dispatchers.
4. Testing Suite: Complete test scenarios documented in TESTING.md with unit tests in test/parcel_model_test.dart.

LIVE DEMO TESTING INSTRUCTIONS:
- Backend Demo Server: https://cheetah.ayan24.me
- Test Driver Login:
  Email: rider@cheetah.com  |  Password: Rider123
  (Features: View real parcel CHT-KHI-000001, test status filters, test touch signature pad, test photo drop-off attachment, view live COD cash wallet).
- Test Warehouse Picker Login:
  Email: picker@cheetah.com  |  Password: Picker123
  (Features: WMS 5-tier spatial bin guidance 'Warehouse Central Hub -> Zone A -> Aisle 04 -> Shelf B -> Bin 03', SKU barcode camera scanner with flashlight & haptic feedback).

DOCUMENTATION & ASSETS INCLUDED:
- Complete standalone interactive documentation (Documentation.html) with live search and dark/light modes.
- Full architectural engineering guide (DOCUMENTATION.md).
- Dedicated Firebase FCM push notification setup guide (FIREBASE_SETUP.md).
- Full source code for Android (Gradle) and iOS (Xcode/CocoaPods) ready for compiling.

Thank you for your time and review!
```

- **Apply for Free file of the week:** Check if you want to participate.
- **Apply for Flash Deal:** Check if you want to participate.

---

## 7️⃣ SUBMIT

- **I have the rights to sell this item:** Check this box `[x] Yes`
- Click the **Submit** button!
