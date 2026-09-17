# iOS Platform Implementation & CoreBluetooth Mechanics

## 1. iOS Architectural Overview

Operating an autonomous peer-to-peer mesh on Apple iOS requires addressing Apple's background execution rules and sandboxing restrictions.

---

## 2. CoreBluetooth Background Modes

Emergixx declares the following background execution keys in `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
    <string>fetch</string>
    <string>processing</string>
</array>
```

### State Restoration (`CBCentralManager` & `CBPeripheralManager`)
When instantiated, Emergixx registers unique state restoration identifiers:
```swift
let centralManager = CBCentralManager(
    delegate: self,
    queue: meshQueue,
    options: [CBCentralManagerOptionRestoreIdentifierKey: "EmergixxCentralRestorationKey"]
)

let peripheralManager = CBPeripheralManager(
    delegate: self,
    queue: meshQueue,
    options: [CBPeripheralManagerOptionRestoreIdentifierKey: "EmergixxPeripheralRestorationKey"]
)
```
If iOS terminates the application in the background due to memory pressure, the OS will automatically relaunch the app into the background when a new peripheral advertising the Emergixx Service UUID is detected.

---

## 3. iOS Screen-Locked Limitations & Workarounds

Apple enforces strict constraints when an iPhone screen is locked:
1. **Advertising Data Stripping**: When an iOS app advertises in the background, its local name and service data are moved into an internal "overflow area" detectable only by iOS devices actively scanning with the exact service UUID specified.
   - *Mitigation*: Emergixx scans explicitly with `[CBUUID(string: "45580001-0000-1000-8000-00805F9B34FB")]`, ensuring background discovery works between iOS devices.
2. **Scan Frequency Throttling**: The scan window is drastically widened when the device enters sleep.
   - *Mitigation*: Emergixx leverages Android and desktop relay courier nodes in mixed disaster theaters to bridge iOS-to-iOS encounters.

---

## 4. Apple Critical Alerts Entitlement

For first responders and emergency personnel, Emergixx requests Apple's **Critical Alerts Entitlement** (`com.apple.developer.usernotifications.critical-alerts`):
- Allows audio distress sirens to sound even when the iPhone is set to **Silent Mode** or **Do Not Disturb**.
- Volume can be set to 100% programmatically for life-safety SOS notifications.

```swift
let center = UNUserNotificationCenter.current()
center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
    // Handle authorization result
}
```

---

## 5. Local Network Privacy Permissions

Starting with iOS 14, apps using local Wi-Fi multicast or P2P connections must declare `NSLocalNetworkUsageDescription`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Emergixx connects to nearby emergency responders and survivors over local Wi-Fi when cellular service is down.</string>
<key>NSBonjourServices</key>
<array>
    <string>_emergixx._tcp</string>
</array>
```
