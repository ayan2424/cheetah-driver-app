# 🍇 CodeGrape Product Submission Guide — Cheetah Driver & Warehouse Picker App (Flutter)

> **Instructions for Seller:** This document is formatted step-by-step for the **CodeGrape Item Upload Form** (`https://www.codegrape.com/upload`). Every field to copy has a convenient code block so you can hover, click **Copy**, and paste directly into CodeGrape!

---

## 1️⃣ STEP 1: ITEM DETAILS & INFORMATION

### Item Name (Title)
*(Copy & paste into the **Item Name** input box)*

```text
Cheetah - Delivery Driver & Warehouse Picker Mobile App (Flutter)
```

---

### Category & Subcategory
*(Select these from the dropdown menus)*

- **Main Category:** `Mobile Apps` (or `Applications` / `Mobile`)
- **Sub Category / Child Category:** `Flutter` *(If Flutter is not listed as a subcategory, select `Android` or `iOS`)*

---

### Demo URL
*(Copy & paste into the **Demo URL** / **Live Preview** field)*

```text
https://cheetah.ayan24.me
```

---

### YouTube Video Demo URL *(Optional)*
*(If you have a video recording on YouTube, add its link here)*

```text
https://www.youtube.com/watch?v=YOUR_VIDEO_ID
```

---

### Item Description
*(Copy & paste this HTML into the **Description** editor. Make sure to click "Source" / "<>" if pasting raw HTML)*

```html
<h3>🛵 Cheetah Driver & Warehouse Picker App — Enterprise Cross-Platform Mobile Suite (Flutter 3.x)</h3>

<p>The <strong>Cheetah Driver & Warehouse Picker Mobile App</strong> is an enterprise-grade, high-performance cross-platform application developed with <strong>Flutter 3.x</strong> and <strong>Dart 3.x</strong>. Engineered as the official mobile companion for the <strong>Cheetah Courier Management & WMS SaaS</strong>, it provides a specialized, role-isolated operational client for both <strong>Courier Delivery Drivers / Riders</strong> and <strong>WMS Warehouse Pickers</strong>.</p>

<p>Whether connected natively to the Cheetah Courier backend or integrated into your own custom logistics REST API, this app delivers 60/120 FPS fluid animations, hardware-level GPS anti-tampering enforcement, digital customer signatures, drop-off photo proof of delivery (POD), live camera barcode scanning, and zero-data-loss AES-256 encrypted offline queueing.</p>

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

<h3>🛡️ Enterprise Features & Reliability</h3>

<ul>
  <li><strong>🔔 Firebase Cloud Messaging (FCM) Ready:</strong> Real-time background wake-on-lock push notifications alerting drivers to newly assigned parcels and warehouse pickers to fresh sales order fulfillment batches.</li>
  <li><strong>🔒 AES-256 Encrypted Offline Queue:</strong> In underground parking lots, basements, or remote delivery routes with zero cell reception, POD records and status updates are encrypted with AES-256 and stored locally in Hive. Automatically syncs when internet returns.</li>
  <li><strong>🛰️ Hardware GPS Anti-Tampering Guard:</strong> Active OS hardware listeners detect any attempt to disable location services, notifying dispatchers instantly with an alert and prompting to re-enable GPS.</li>
  <li><strong>🔐 Hardware-Backed Token Storage:</strong> Tokens stored securely in Android Keystore / iOS Keychain (AES-256 GCM).</li>
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
  <li>iOS Xcode Workspace (CocoaPods, iOS 15.0 to 18.x compatible).</li>
  <li>CodeGrape Help Guide (<code>Help.html</code>) included in the package.</li>
  <li>Firebase Cloud Messaging Setup Guide.</li>
  <li>Step-by-step App Store & Google Play publishing instructions.</li>
</ul>
```

---

### Tags (Search Keywords)
*(Copy & paste into the **Tags** input box on CodeGrape — Comma separated)*

```text
flutter, mobile app, delivery app, courier app, driver app, warehouse picker, wms, gps tracking, live telemetry, proof of delivery, pod signature, barcode scanner, qr scanner, cod wallet, offline sync, logistics, courier driver, flutter 3, android app, ios app, dispatch, shipment tracking
```

---

## 2️⃣ STEP 2: PRICING

*(Enter your license prices in USD)*

- **Regular License:**
```text
49
```
- **Extended License:**
```text
149
```

---

## 3️⃣ STEP 3: FILE UPLOADS & REQUIRED ASSETS

CodeGrape requires specific image sizes and file formats. Here is exactly what you need to upload:

### 1. Thumbnail Image (`80x80` px)
- **Dimensions:** Exactly `80 x 80` pixels.
- **Format:** `PNG` or `JPG` (No spaces in filename, e.g. `thumbnail.png`).
- **Content:** The Cheetah app app-icon or logo with a clean background.

### 2. Preview Image / Cover Banner (`590x300` px)
- **Dimensions:** `590 x 300` pixels (or standard marketplace ratio).
- **Format:** `PNG` or `JPG` (e.g. `preview.jpg`).
- **Content:** A crisp promotional graphic showing the mobile app screens (Driver list, Signature pad, Barcode scanner) with the title *"Cheetah Driver & Warehouse App"*.

### 3. Main ZIP File (`Upload.zip`)
- **What to upload:** The clean zip of your `Upload` folder (which contains `lib/`, `android/`, `ios/`, `assets/`, `pubspec.yaml`, and the `Help.html` file we just created).
- **Size limit:** Must be under 100MB (Your cleaned folder is very small, ~3MB to 5MB, so it will upload in seconds!).
- **Filename:** `cheetah_driver_app.zip` (Avoid spaces or symbols).

### 4. Screenshots ZIP *(Optional)*
- **What to upload:** A `.zip` file containing 5 to 10 screenshots of the app (e.g., `screenshots.zip`).
- Buyers can browse these screenshots to view all screens before purchasing.

---

## 4️⃣ STEP 4: MESSAGE TO REVIEWER / COMMENTS

*(Copy & paste into the **Message to reviewer / Comments** field)*

```text
Hello CodeGrape Review Team,

Thank you for reviewing the Cheetah Driver & Warehouse Picker Mobile App (Flutter 3.x / Dart 3.x).

This is an original, production-grade logistics client engineered for courier riders and warehouse pickers. It contains zero AI wrappers, zero license locks, zero obfuscation, and zero third-party domain restrictions.

KEY HIGHLIGHTS:
1. Static Analysis: Passed 'flutter analyze' with 0 errors and 0 warnings.
2. OS Compatibility: 
   - Android: Min SDK 21 (Android 5.0), Target SDK 34/35 (Android 14 & 15).
   - iOS: Target iOS 15.0 to 18.x (CocoaPods ready).
3. Offline Resiliency: Uses Hive with AES-256 local encrypted storage for zero-data-loss POD capture in dead cell zones.
4. Security: Tokens stored securely in hardware-backed Android Keystore / iOS Keychain.
5. Documentation: Included CodeGrape-compliant 'Help.html' guide inside the main zip root.

LIVE DEMO CREDENTIALS:
- Backend Demo URL: https://cheetah.ayan24.me
- Test Driver Login: rider@cheetah.com / Password: Rider123
- Test Warehouse Picker Login: picker@cheetah.com / Password: Picker123

Thank you for your review!
```

---

## 5️⃣ SUBMIT
- Check the declaration box confirming you hold the rights to sell this item.
- Click **Save / Submit for Review**!
