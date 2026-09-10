# 🍇 CodeGrape Product Submission Guide — Cheetah Driver & Warehouse Picker App (Flutter)

> **Instructions for Seller:** This document is formatted to match the **CodeGrape Upload Form** field-by-field as shown in your screenshot. Hover over any grey code box to click the **Copy** button, then paste directly into CodeGrape!

---

## 1️⃣ NAME & DESCRIPTION

### Name
*(Copy & paste into the **Name** input box)*

```text
Cheetah - Delivery Driver & Warehouse Picker Mobile App (Flutter)
```

---

### Description
*(Copy & paste this HTML into the **Description** editor. Make sure to click the **`<> Source`** button on the toolbar first, paste the code, and click `Source` again)*

```html
<h3>🛵 Cheetah Driver & Warehouse Picker App — Enterprise Cross-Platform Mobile Suite (Flutter 3.x)</h3>

<p>The <strong>Cheetah Driver & Warehouse Picker Mobile App</strong> is an enterprise-grade, high-performance cross-platform application developed with <strong>Flutter 3.x</strong> and <strong>Dart 3.x</strong>. Engineered as the official mobile companion for the <strong>Cheetah Courier Management & WMS SaaS</strong>, it provides a specialized, role-isolated operational client for both <strong>Courier Delivery Drivers / Riders</strong> and <strong>WMS Warehouse Pickers</strong>.</p>

<p><strong>🔥 100% SELF-CONTAINED FULL-STACK SOLUTION:</strong> Unlike typical client-only mobile apps that require expensive proprietary software, this package <strong>includes a complete standalone PHP REST API backend, ready-to-import MySQL database, and official Postman collection</strong>. You can host and run this system independently on any standard cPanel, shared hosting, Apache, LiteSpeed, Nginx, or cloud VPS within 5 minutes!</p>

<hr>

<h3>📱 Live Demo & APK Testing</h3>

<p>You can test both the mobile companion application and the live dispatch backend before purchasing:</p>

<p>👉 <strong>📥 Download Android Demo APK:</strong> <br>
<a href="https://drive.google.com/drive/folders/1Ul3lGfaKFBJUpGvX-2vkYimJDzXMoiXj?usp=sharing" target="_blank"><strong>Click Here to Download Demo APK (Google Drive)</strong></a><br>
<em>(Install the APK directly on your Android phone or emulator to test the full mobile experience)</em></p>

<p>👉 <strong>🌐 Live Web Dispatcher Backend:</strong> <br>
<a href="https://cheetah.ayan24.me" target="_blank"><strong>https://cheetah.ayan24.me</strong></a></p>

<p><strong>🔑 Demo Login Accounts (for both App and Web):</strong></p>
<ul>
  <li><strong>🚗 Delivery Driver Demo:</strong> <code>rider@cheetah.com</code> / Password: <code>Rider123</code><br>
  <em>(Features: Real shipments timeline, digital signature pad, photo POD capture, COD wallet ledger, turn-by-turn GPS navigation)</em></li>
  <li><strong>🏗️ Warehouse Picker Demo:</strong> <code>picker@cheetah.com</code> / Password: <code>Picker123</code><br>
  <em>(Features: 5-tier spatial bin guidance, SKU barcode/QR camera scanner with flashlight & haptic feedback)</em></li>
</ul>

<hr>

<h3>🌟 Dual-Role Operational Capabilities</h3>

<h4>1. 🛵 Delivery Driver / Courier Rider Portal</h4>
<ul>
  <li><strong>Smart Delivery Pipeline:</strong> View assigned shipments categorized by status (<em>Assigned</em>, <em>Out for Delivery</em>, <em>Delivered</em>, <em>Failed / Returned</em>).</li>
  <li><strong>Branded CHT- Tracking Compatibility:</strong> Natively parses, detects, and displays branded <code>CHT-{ORIGIN_CODE}-{SERIAL}</code> tracking numbers with instant camera barcode recognition.</li>
  <li><strong>Turn-by-Turn GPS Navigation:</strong> One-tap routing integration with Google Maps, Apple Maps, and Waze directly from parcel destination addresses.</li>
  <li><strong>Instant Customer Contact:</strong> 1-tap phone calls and direct WhatsApp chat integration to connect with senders and receivers.</li>
  <li><strong>Proof of Delivery (POD) Suite:</strong>
    <ul>
      <li>Smooth touchscreen digital signature pad with PNG export.</li>
      <li>Drop-off photo capture via device camera or gallery upload with server-side watermarking.</li>
      <li>Customer delivery OTP (One-Time Password) verification support.</li>
      <li>Receiver name and handover delivery remarks logging.</li>
    </ul>
  </li>
  <li><strong>Cash on Delivery (COD) Wallet Ledger:</strong> Real-time tracking of collected COD cash, pending branch vault deposits, and driver payout transaction history with idempotency key protection.</li>
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

<h3>🖥️ Standalone PHP REST API Backend Included</h3>
<ul>
  <li><strong>Standalone PHP 8.0+ Backend:</strong> Pure PHP with <code>mysqli</code> prepared statements — zero framework overhead.</li>
  <li><strong>MySQL Database Dump:</strong> Complete <code>driver_app.sql</code> database script with pre-seeded demo drivers, pickers, branches, active parcels, and pick tasks.</li>
  <li><strong>Official Postman Collection (v2.1):</strong> Pre-configured Postman Collection & Environment with automated bearer token authentication.</li>
  <li><strong>Universal Hosting Compatibility:</strong> Runs effortlessly on any standard cPanel shared hosting, Apache, Nginx, or VPS.</li>
</ul>

<hr>

<h3>🛡️ Enterprise Features & Reliability</h3>

<ul>
  <li><strong>🔔 Firebase Cloud Messaging (FCM) Ready:</strong> Real-time background wake-on-lock push notifications alerting drivers to newly assigned parcels and warehouse pickers to fresh sales order fulfillment batches.</li>
  <li><strong>🔒 AES-256 Encrypted Offline Queue:</strong> In underground parking lots, basements, or remote delivery routes with zero cell reception, POD records and status updates are encrypted with AES-256 and stored locally in Hive. Automatically retries and flushes queued uploads upon reconnect.</li>
  <li><strong>🛰️ Hardware GPS Anti-Tampering Guard:</strong> Active OS hardware listeners detect any attempt to disable location services, notifying dispatchers instantly and prompting to re-enable GPS.</li>
  <li><strong>🔐 Hardware-Backed Token Storage:</strong> Tokens stored securely in Android Keystore / iOS Keychain (AES-256 GCM via flutter_secure_storage).</li>
  <li><strong>🌐 23-Language Support with Full RTL:</strong> Pre-configured with translations for English, Spanish, Arabic (with native RTL layout mirroring), French, German, Hindi, Urdu, Portuguese, Russian, and Chinese.</li>
  <li><strong>🌓 Dark & Light Glassmorphic UI:</strong> Stunning, high-contrast visual design with system auto-detection and manual toggle.</li>
  <li><strong>📱 Universal Device Compatibility:</strong> Fully optimized for smartphones, tablets, and rugged industrial handheld Android barcode scanners (Zebra, Honeywell, Newland).</li>
  <li><strong>☁️ 1-Click Cloud Builds via GitHub Actions (Zero Local Setup Required!):</strong> Low-spec computer or don't own a Mac? Includes pre-configured GitHub Actions CI/CD workflows for both <strong>Android</strong> (<code>android-build.yml</code> — compiles Release APK &amp; Google Play AAB) and <strong>iOS</strong> (<code>ios-simulator-build.yml</code> — compiles iOS build on cloud macOS runners). Simply push to GitHub and download your compiled builds directly!</li>
</ul>

<hr>

<h3>📦 What You Will Receive</h3>
<ul>
  <li>Full Flutter 3.x & Dart 3.x Source Code (Clean GetX Architecture).</li>
  <li><strong>Complete Standalone PHP REST API Backend Source Code (<code>backend/</code>).</strong></li>
  <li><strong>Ready-to-Import MySQL Database Dump (<code>backend/database/driver_app.sql</code>).</strong></li>
  <li><strong>Official Postman Collection v2.1 & Environment (<code>postman/</code>).</strong></li>
  <li>Android Project Workspace (Gradle, Android 14/15 Target SDK 34/35, Min SDK 21).</li>
  <li>iOS Xcode Workspace (CocoaPods ready, iOS 15.0 to 18.x compatible).</li>
  <li>Interactive CodeGrape-Compliant Help Guide (<code>Help.html</code>) included in the root.</li>
  <li>Backend Deployment & Configuration Guide (<code>backend/README.md</code>).</li>
  <li>Dedicated Firebase Cloud Messaging Setup Guide.</li>
  <li><strong>Automated Cloud Build CI/CD Workflows (<code>.github/workflows/</code>) — 1-click cloud builds for both Android (APK &amp; AAB) and iOS without installing local SDKs!</strong></li>
  <li>Step-by-step App Store & Google Play publishing instructions.</li>
</ul>
```

---

### Tags
*(Copy & paste into the **Tags** input box)*

```text
flutter, mobile app, delivery app, courier app, driver app, warehouse picker, wms, gps tracking, live telemetry, proof of delivery, pod signature, barcode scanner, qr scanner, cod wallet, offline sync, logistics, courier driver, flutter 3, android app, ios app, dispatch, shipment tracking
```

---

### Price
*(Enter in the **Price ($ USD)** field)*

```text
49
```

---

## 2️⃣ FILES

*(Upload your files in the Drag & Drop area, then select them in the respective dropdowns below)*

### 1. Thumbnail
- **Requirement:** `80x80 JPEG/PNG`
- **What to upload:** Square app logo or icon sized exactly **80x80 pixels** (e.g. `thumbnail.png`).
- Select your uploaded file from the dropdown.

### 2. Preview Image
- **Requirement:** `590x242 JPEG/PNG` *(As specified on your CodeGrape upload form)*
- **What to upload:** Promotional landscape cover graphic sized exactly **590x242 pixels** (e.g. `preview.jpg`) showcasing the mobile app UI and title.
- Select your uploaded file from the dropdown.

### 3. Screenshots
- **Requirement:** `ZIP - Files of Images (JPEG/PNG)`
- **What to upload:** A `.zip` file containing 5 to 10 screenshots of the app screens (e.g. `screenshots.zip`).
- Select your uploaded zip file from the dropdown.

### 4. Main File(s)
- **Requirement:** `ZIP - All Files for Download`
- **What to upload:** The clean zip of your `Upload` folder (`cheetah_driver_app.zip` containing `lib/`, `android/`, `ios/`, `assets/`, `pubspec.yaml`, and `Help.html`).
- Select your uploaded zip file from the dropdown.

> **⚠️ Important Notice on Corrupt Zip Files:** CodeGrape warns against using 7-Zip, Izarc, or latest WinZip. Use standard Windows built-in zip (Right-click folder -> *Send to* -> *Compressed (zipped) folder*) to ensure 100% compatibility.

---

## 3️⃣ CATEGORY & ATTRIBUTES

### Category
- Select `Mobile Apps` (or `Flutter` / `Android` / `Scripts` depending on dropdown options).

### Demo URL
*(Copy & paste into the **Demo URL** field)*

```text
https://cheetah.ayan24.me
```

*(Note: The Google Drive Demo APK download link is already prominently placed in the Description above for buyers to download and install!)*

---

## 4️⃣ MESSAGE TO THE REVIEWER

### Comments
*(Copy & paste into the **Comments** text area)*

```text
Hello CodeGrape Review Team,

Thank you for reviewing the Cheetah Driver & Warehouse Picker Mobile App (Flutter 3.x / Dart 3.x).

This is a production-grade, hand-crafted enterprise logistics client built from the ground up for delivery drivers and warehouse pickers. It contains zero AI wrappers, zero license locks, zero domain restrictions, and zero obfuscation.

KEY PRODUCTION HIGHLIGHTS:
1. Complete Turnkey Full-Stack: Includes standalone PHP 8.0+ REST API backend (backend/), ready MySQL DB dump (driver_app.sql), and official Postman collection (postman/).
2. Static Analysis & Code Quality: Passed 'flutter analyze' with 0 errors and 0 warnings. Pure PHP mysqli prepared statements with zero syntax errors.
3. Automated 1-Click Cloud Builds (.github/workflows/): Pre-configured CI/CD workflows for Android (Release APK & AAB) and iOS builds without local SDK setup.
4. OS Compatibility: 
   - Android: Min SDK 21 (Android 5.0), Target SDK 34/35 (Android 14 & 15).
   - iOS: Target iOS 15.0 to 18.x (CocoaPods ready).
5. Hardware Security: Tokens stored in Android Keystore / iOS Keychain (AES-256 GCM).
6. Offline POD Queue: Uses Hive with AES-256 local encryption and automatic re-sync upon network restore.
7. Documentation: Included CodeGrape-compliant 'Help.html' guide inside the main package root.

DEMO ACCESS & TESTING:
- Live Dispatch Backend: https://cheetah.ayan24.me
- Downloadable Android Demo APK: https://drive.google.com/drive/folders/1Ul3lGfaKFBJUpGvX-2vkYimJDzXMoiXj?usp=sharing
- Test Driver Login: rider@cheetah.com / Password: Rider123
- Test Warehouse Picker Login: picker@cheetah.com / Password: Picker123

Thank you for your review and support!
```

### Declaration Checkbox
- Check the box:  
  `[x] Any images / sounds / video / code used which are not my own work have been appropriately licensed for resale. Other than these items, this work is entirely my own and I have full rights to sell it on CodeGrape.`

### Action
- Click the green **`Upload`** button!
