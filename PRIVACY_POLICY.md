# Privacy Policy for Cheetah Driver & Warehouse Picker App

**Effective Date:** September 8, 2026  
**Last Updated:** September 8, 2026  

This Privacy Policy describes how the **Cheetah Driver & Warehouse Picker Mobile Application** ("the Application"), developed by Cheetah Logistics, collects, uses, stores, and protects user data when delivery couriers and warehouse fulfillment pickers use our mobile software suite.

---

## 1. Information We Collect

### A. Location Information (Precise & Background Telemetry)
- **What We Collect:** High-accuracy GPS coordinates (latitude, longitude, altitude, speed, and heading) and device GPS sensor status.
- **Why We Collect It:** 
  - To provide real-time turn-by-turn navigation from current location to recipient delivery addresses.
  - To transmit live delivery progress and vehicle telemetry to central dispatchers and customer live-tracking links while deliveries are in transit.
  - To record non-repudiation geostamps on Electronic Proof of Delivery (ePOD) handover events.
- **Background Location:** When a courier has shipments marked "Out for Delivery", location updates may be transmitted in the background at 30-second intervals to keep dispatcher fleet maps synchronized. Drivers are notified via an active persistent Android notification whenever background tracking is engaged.

### B. Camera & Image Data
- **What We Collect:** Touchscreen digital signature vectors and photographs of delivered parcels captured via the device camera or selected from the image gallery.
- **Why We Collect It:**
  - Electronic Proof of Delivery (ePOD) to verify successful parcel handover.
  - Server-side non-repudiation watermarking (overlaying tracking number, timestamp, and courier name).
  - High-speed barcode and QR code scanning for parcel intake and warehouse bin picking.
- **Data Protection:** Captured images and signatures are encrypted during transit via HTTPS/TLS 1.3 and stored in secured server storage.

### C. Device & Operational Telemetry
- **What We Collect:** Device manufacturer, OS version, battery level, network connection state (online/offline), and Firebase Cloud Messaging (FCM) push notification tokens.
- **Why We Collect It:**
  - To wake the device for urgent order dispatch alerts.
  - To optimize battery usage during long-haul delivery routes.
  - To manage encrypted local offline queue synchronization via Hive (AES-256).

---

## 2. How Data is Used & Stored

- **Strict Operational Scoping:** Courier location and delivery data is used strictly for logistics routing, parcel handover verification, and cash collection reconciliation.
- **Zero Third-Party Advertising:** We do NOT sell, lease, or monetize courier personal data, location traces, or customer delivery details to third-party advertisers or data brokers.
- **Local Storage Encryption:** Sensitive authentication tokens and offline delivery queues are stored in hardware-backed secure storage (Android Keystore / Apple iOS Keychain) and locally encrypted with AES-256.

---

## 3. Data Retention & Security

- **Transit Security:** All API communications between the mobile application and the Cheetah REST API backend use industry-standard HTTPS with SHA-256 Bearer token authentication.
- **Retention:** Delivery verification records (ePOD photos, signatures, and timestamps) are retained for audit and dispute resolution in accordance with commercial logistics standards.

---

## 4. Permissions Required & User Control

| Permission | OS Level | Purpose | Mandatory / Optional |
| :--- | :--- | :--- | :--- |
| **Location (Fine & Coarse)** | Android & iOS | Route navigation & live dispatch map | Mandatory for active delivery shifts |
| **Background Location** | Android 10+ / iOS | Fleet tracking during transit | Mandatory during "Out for Delivery" |
| **Camera** | Android & iOS | Barcode scanning & delivery drop-off photos | Mandatory for POD submission |
| **Storage / Photos** | Android & iOS | Saving POD photos & profile avatar | Optional (fallback to live camera) |
| **Notifications** | Android 13+ / iOS | Dispatch alerts & priority route changes | Recommended |

Users may revoke optional permissions at any time through their device operating system settings.

---

## 5. Contact & Data Deletion Inquiries

For questions regarding this Privacy Policy, or to request deletion of personal driver data, please contact:

- **Entity:** Cheetah Logistics Solutions
- **Email:** support@cheetah.ayan24.me
- **Support Portal:** https://cheetah.ayan24.me
