# 🔥 Firebase Cloud Messaging (FCM) & Push Notifications Setup Guide

This guide explains how to activate **Push Notifications** for the Cheetah Courier Driver & Picker Mobile App.

---

## ⚡ Standalone Mode vs Firebase Mode

* **Standalone Mode (Default):** The Cheetah Driver App runs 100% independently using pure PHP REST APIs with zero external dependencies. No Firebase setup is strictly required.
* **Firebase Mode (Optional):** Activating Firebase adds instant background sound alerts, wake-on-lock notifications, and real-time dispatch pings to drivers.

---

## 🚀 3-Minute Quick Setup

### Step 1: Create a Free Google Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/) and sign in with your Google Account.
2. Click **"Add Project"**, name it (e.g. `cheetah-courier`), and click **Continue**.
3. Google Analytics is optional. Choose the **100% Free Spark Plan** (unlimited push notifications).

---

### Step 2: Configure FCM Key in Cheetah Admin Panel
1. In Firebase Console, click the **Gear Icon ⚙️ (Project Settings)** in the top left.
2. Open the **Cloud Messaging** tab.
3. Copy your **Server Key** (or Cloud Messaging API Token).
4. Log in to your Cheetah Admin Panel:
   - Navigate to: **Admin Dashboard → Integrations Hub → Firebase & Push (FCM)**.
   - Turn **ON** the *Enable Firebase Push Notifications* switch.
   - Paste your **Firebase Project ID** and **FCM Server Key**.
   - Click **Save Firebase Settings**.

---

### Step 3: Add `google-services.json` to the Flutter App
1. In Firebase Console under **Project Settings → General**, scroll down to *Your Apps* and click the **Android Icon 🤖**.
2. Enter the Package Name: `com.cheetah.courier.driver`
3. Click **Register App** and download the `google-services.json` file.
4. Replace the template file at:
   ```
   cheetah_driver_app/android/app/google-services.json
   ```
5. Build your app release APK:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Testing Your Notifications

1. Open the Driver Mobile App and log in with any driver or picker account.
2. Go to **Admin Dashboard → Integrations Hub → Firebase & Push (FCM)**.
3. Under **Live Test Push Notification**, select your driver from the dropdown list.
4. Click **Send Test Notification**.
5. Your driver's mobile device will instantly receive a floating sound alert & notification! 🎉

---

## 🛠️ Automated Dispatch Events

Once enabled, Cheetah automatically sends push notifications to drivers for:
* 📦 **New Parcel Assigned:** Driver receives an alert with tracking number, customer name, and city.
* 📋 **Warehouse Pick Task Assigned:** WMS pickers receive instant task notifications.
* 🚨 **Urgent Order Updates:** Order status changes or cancellations.
