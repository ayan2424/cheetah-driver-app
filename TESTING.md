# 🧪 Cheetah Driver App — Quality Assurance & Testing Matrix

This document provides testing procedures, role credentials, edge case scenarios, and validation checklists for the **Cheetah Driver & Warehouse Picker Mobile App** integrated with the live backend at `https://cheetah.ayan24.me`.

---

## 🎯 Test Objectives
1. Verify role-based routing and bottom navigation switches (`driver` vs `picker`).
2. Validate the offline Proof of Delivery (POD) capture, AES-256 local encryption, and auto-sync on reconnect.
3. Validate server-side non-repudiation watermark burning on uploaded proof photos.
4. Verify the 30-second GPS telemetry stream and real-time OS hardware toggle guard.
5. Validate Cash on Delivery (COD) collection accounting ledger and wallet commission increments.
6. Verify graceful fallback when Firebase Cloud Messaging is unconfigured (Standalone Mode).

---

## 🔐 Test Personas & Credentials

| Persona / Role | Email | Purpose / Testing Focus |
| :--- | :--- | :--- |
| **Courier Driver (Karachi Hub)** | `driver@cheetah.com` | Assigned delivery manifest, POD signature pad, camera proof, COD cash ledger, live GPS tracking. |
| **Warehouse Picker (Central WMS)** | `picker@cheetah.com` | Warehouse pick waves, bin/shelf guidance, barcode scanning, order completion hooks. |
| **System Admin (Web Portal)** | `admin@cheetah.com` | Dispatch live map, parcel assignment, branch scoping, and settlement approval. |

*Default test password:* `password123` (or as configured on `https://cheetah.ayan24.me/admin`)

---

## 📋 Comprehensive Test Matrix

### 1. Authentication & Session Security

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **AUTH-01** | Valid Driver Login | 1. Enter driver credentials.<br>2. Tap 'Sign In'. | Authenticates successfully, stores SHA-256 token in hardware secure storage, navigates to Driver Home (5 tabs). | ✅ PASS |
| **AUTH-02** | Valid Picker Login | 1. Enter picker credentials.<br>2. Tap 'Sign In'. | Authenticates, navigates to Picker Home (2 tabs: WMS Picking & Profile). | ✅ PASS |
| **AUTH-03** | Invalid Password Rejection | 1. Enter valid email with wrong password. | Rejects with descriptive error message; does not persist invalid session. | ✅ PASS |
| **AUTH-04** | Hardware Token Persistence | 1. Log in.<br>2. Kill and restart the mobile app. | Splash screen reads token from Keystore/Keychain and restores active session without re-prompting login. | ✅ PASS |
| **AUTH-05** | Session Revocation (401) | 1. Revoke driver session on backend.<br>2. Perform any API action in app. | Halts background GPS tracking, wipes secure token, redirects to Login with session expired alert. | ✅ PASS |

---

### 2. Delivery Manifest & Barcode Search

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **DELIV-01**| Manifest Isolation | 1. Log in as Driver A.<br>2. Inspect deliveries tab. | Only displays shipments where `driver_id == Driver A` and `branch_id == Driver A branch`. | ✅ PASS |
| **DELIV-02**| Substring Search | 1. Type partial tracking # or recipient name in search bar. | List instantly filters matching items in real time. | ✅ PASS |
| **DELIV-03**| Hardware Barcode Scan | 1. Tap barcode scanner icon.<br>2. Scan printed AWB label barcode. | Camera closes, search bar populates with scanned AWB, and matching parcel is highlighted. | ✅ PASS |
| **DELIV-04**| Multi-Status Filter Chips | 1. Tap 'Out for Delivery', 'In Transit', 'Delivered'. | List immediately re-renders shipments matching the selected status chip. | ✅ PASS |
| **DELIV-05**| Pull-to-Refresh | 1. Pull down on delivery list. | Triggers `fetchParcels()`, updates parcel list and summary stats from backend. | ✅ PASS |

---

### 3. Proof of Delivery (POD) & Offline Queueing

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **POD-01** | Online Delivery Flow | 1. Select active parcel.<br>2. Tap 'Deliver Package'.<br>3. Enter receiver name, sign on touch canvas, capture camera photo.<br>4. Tap 'Submit POD'. | Uploads multipart payload to backend. Status updates to `Delivered`, stats update, and COD ledger increments. | ✅ PASS |
| **POD-02** | Mandatory OTP Verification | 1. Attempt delivery on parcel with `requires_otp == true`.<br>2. Leave OTP empty. | Form validation prevents submission until valid 4-digit recipient PIN is provided. | ✅ PASS |
| **POD-03** | Server Watermark Inspection | 1. Submit delivery photo.<br>2. View parcel proof on web portal (`https://cheetah.ayan24.me/track`). | Image displays semi-transparent bottom banner with tracking #, UTC timestamp, and driver name. | ✅ PASS |
| **POD-04** | Offline POD Intercept | 1. Enable Airplane Mode (disable Wi-Fi & Cellular).<br>2. Submit POD with photo & signature. | App catches offline state, saves AES-256 encrypted payload in local Hive queue, shows 'Saved Locally' toast. | ✅ PASS |
| **POD-05** | Auto-Sync on Network Restore | 1. With items in offline queue, disable Airplane Mode (reconnect internet). | `OfflineSyncService` detects connectivity transition, sequentially uploads queued PODs, and evicts from queue upon 200 OK. | ✅ PASS |

---

### 4. Fleet GPS Telemetry & Hardware Sensor Guard

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **GPS-01** | Periodic 30s Telemetry | 1. Log in as driver on active shift.<br>2. Inspect web dispatch map (`/admin/fleet`). | Mobile client sends position coordinates every 30 seconds. Dispatcher pin updates smoothly. | ✅ PASS |
| **GPS-02** | Hardware Toggle Intercept | 1. Turn off device Location toggle from Android/iOS quick settings. | Stream listener detects state in <0.1s. Sends `gps_enabled = 0` to server. Displays non-dismissible modal. | ✅ PASS |
| **GPS-03** | Hardware Recovery | 1. Tap 'Turn on GPS' button on modal.<br>2. Enable Location in OS settings. | Modal dismisses automatically, normal 30s location tracking resumes. | ✅ PASS |
| **GPS-04** | App Minimized / Resumed | 1. Minimize app while on duty.<br>2. Open app after 5 minutes. | `WidgetsBindingObserver` re-enforces location check and syncs current coordinates. | ✅ PASS |

---

### 5. Warehouse Management System (WMS) Picking

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **WMS-01** | Pick Task Ingestion | 1. Log in as Picker.<br>2. Open 'Warehouse Pick Tasks'. | Displays assigned sales orders, bin locations (Zone/Aisle/Shelf), and required unit quantities. | ✅ PASS |
| **WMS-02** | Start Picking Transition | 1. Tap 'Start Picking' on a pending task. | Updates task status to `In Progress` in Cheetah WMS database. | ✅ PASS |
| **WMS-03** | Complete Pick Task | 1. Tap 'Complete Task'. | Updates task to `Completed`. Backend automatically transitions linked sales order to `Prepared` state. | ✅ PASS |

---

### 6. COD Cash Ledger & Driver Wallet

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **COD-01** | Pending Cash Calculation | 1. Review 'COD Log' tab. | Correctly sums all unpaid COD shipments currently assigned for delivery. | ✅ PASS |
| **COD-02** | Cash Collection Shift Handover | 1. Deliver COD parcel.<br>2. Check daily performance card. | Delivered count increments, pending COD updates, and collected cash is logged for end-of-shift branch drop. | ✅ PASS |
| **COD-03** | Driver Commission Wallet | 1. Open 'Wallet' tab.<br>2. Verify pending commission balance and disbursement history. | Reflects earned per-parcel commissions and approved payouts from branch accounting. | ✅ PASS |

---

### 7. Localization & Themes

| ID | Test Scenario | Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **UI-01** | Dark / Light Theme Toggle | 1. Tap theme button on AppBar or Profile tab. | All UI cards, texts, borders, and modal bottom sheets cleanly transition between dark and light themes. | ✅ PASS |
| **UI-02** | 9-Language Switching | 1. Select language (English, Swahili, Urdu, Arabic, French, Spanish, German, Turkish, Chinese). | Entire UI immediately updates to selected language dictionary with proper RTL support for Urdu & Arabic. | ✅ PASS |

---

## 🛠 Test Execution Notes
- Automated static analysis passed with **0 errors and 0 warnings** via `flutter analyze`.
- Endpoints verified with pure PHP 8.0+ / MySQLi backend running in production at `https://cheetah.ayan24.me`.
