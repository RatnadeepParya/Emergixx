# Android Platform Implementation & Background Mechanics

## 1. Android Architectural Overview

Maintaining continuous peer-to-peer mesh connectivity on Android requires navigating strict operating system power management systems, including **Doze Mode**, **App Standby Buckets**, and **Background Execution Limits**.

---

## 2. Foreground Emergency Service

Emergixx implements an Android Foreground Service (`EmergixxRelayService`) with foreground service type `connectedDevice` and `location`:

```xml
<service
    android:name=".service.EmergixxRelayService"
    android:foregroundServiceType="connectedDevice|location"
    android:exported="false" />
```

### Persistent Life-Safety Notification
The service displays an un-swipeable system notification:
- **Title**: `Emergixx Mesh Active`
- **Body**: `Connected to 3 nearby peers. Relaying emergency distress packets.`
- **Priority**: `PRIORITY_HIGH` (Android 7.1 and lower) / `IMPORTANCE_HIGH` (Android 8.0+)
- **Channel**: `emergixx_mesh_channel`

This prevents the Android Low Memory Killer (LMK) from terminating the process while the phone screen is turned off.

---

## 3. Runtime Permissions Strategy (Android 12+)

Android 12 (API 31) separated Bluetooth scanning and advertising permissions from coarse/fine location. Emergixx requests:

```xml
<!-- Android 12+ Granular Bluetooth Permissions -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Wi-Fi Direct & Local Discovery -->
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### Justification Dialog
Before prompting for system permissions, the UI displays a clear life-safety explanation to the user:
> *"Emergixx requires Nearby Devices and Background Location permissions to detect neighboring devices over Bluetooth and Wi-Fi Direct and relay SOS alerts when the screen is locked."*

---

## 4. Battery Optimization & Doze Mode Exemption

In extreme disaster situations where cell towers are down, the user is prompted to exempt Emergixx from system battery optimizations:

```kotlin
val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
    data = Uri.parse("package:$packageName")
}
startActivity(intent)
```

### WakeLocks
A partial `WakeLock` (`PowerManager.PARTIAL_WAKE_LOCK`) is held only during active BLE GATT batch transfers (maximum 10 seconds per session), then immediately released to conserve milliampere-hours.

---

## 5. Hardware Limitations & Mitigations

1. **BLE Advertising Limit**: Some budget Android chipsets limit concurrent BLE advertising to 4 packets per second. Emergixx paces advertisements dynamically.
2. **Wi-Fi Direct Coexistence**: Running Wi-Fi Direct concurrent with Bluetooth can cause 2.4 GHz radio frequency interference on single-antenna chipsets. Emergixx schedules Wi-Fi P2P bursts alternately with BLE scan windows.
