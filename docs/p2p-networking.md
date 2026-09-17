# Peer-to-Peer Physical Networking

## 1. Overview

Emergixx leverages two complementary short-range physical wireless radio transports:
1. **Bluetooth Low Energy (BLE) GATT**: Ultra-low energy consumption, omnidirectional discovery, effective range 10–50 meters.
2. **Wi-Fi Direct / Wi-Fi P2P**: High-bandwidth data transfer, effective range 50–150 meters, used for rapid cluster-head synchronization and bulk map/media transfer.

---

## 2. Bluetooth Low Energy (BLE) Architecture

### Dual-Role Operation (Peripheral & Central)
Every Emergixx mobile node concurrently acts as:
- **GATT Server (Peripheral)**: Advertises service UUID `0000EX01-0000-1000-8000-00805F9B34FB` containing ephemeral device ID `EX-XXXXXX` and battery level.
- **GATT Client (Central)**: Scans for nearby Emergixx peripheral advertisements and initiates short connection sessions to exchange prioritized message batches.

```
       Node A (Central/Client)               Node B (Peripheral/Server)
                 |                                       |
                 |--- BLE Advertising Beacon ----------->|
                 |<-- BLE Scan Response -----------------|
                 |                                       |
                 |--- Connect Request (GATT Connect) --->|
                 |<-- Connected (MTU Negotiation 512B) --|
                 |                                       |
                 |--- Write Characteristic (Batch In) -->|
                 |<-- Write Characteristic (Batch Out) --|
                 |                                       |
                 |--- Disconnect (Save Radio Power) ---->|
                 v                                       v
```

### BLE GATT Service Specifications

- **Emergixx Service UUID**: `45580001-0000-1000-8000-00805F9B34FB`
- **Inbound Characteristic (Write without response)**: `45580002-0000-1000-8000-00805F9B34FB`
- **Outbound Characteristic (Notify / Read)**: `45580003-0000-1000-8000-00805F9B34FB`
- **Identity & Status Characteristic (Read)**: `45580004-0000-1000-8000-00805F9B34FB`

### Fragmentation & MTU Sizing
- Maximum Transmission Unit (MTU) is negotiated up to **512 bytes** on Android and **185 bytes** on iOS.
- Packets exceeding negotiated MTU are segmented using a 4-byte chunk header: `[MsgId: 2B][Seq: 1B][Total: 1B]`.

---

## 3. Wi-Fi Direct (P2P) Architecture

Wi-Fi Direct is activated selectively to prevent excessive battery drain:
- Only enabled when device battery is above 30%.
- Activated when large batches (>5 packets) or high-priority distress alerts require immediate broad propagation.
- Autonomous group owner (GO) negotiation selects the node with the highest battery level and lowest hop count to coordinate local clusters.

---

## 4. Signal Strength (RSSI) & Distance Estimation

Distance is calculated using the Log-Distance Path Loss model:

$$\text{Distance} = 10^{\frac{A - \text{RSSI}}{10 \cdot n}}$$

Where:
- $A$: Received signal strength at 1 meter (calibrated to $-59\text{ dBm}$).
- $\text{RSSI}$: Current measured signal strength in $\text{dBm}$.
- $n$: Path loss exponent ($n = 2.0$ for open disaster field, $n = 3.2$ for collapsed urban structures).

### Trust & Proximity Thresholds
- $\text{RSSI} > -65\text{ dBm}$: Immediate Proximity (< 5m) — High throughput opportunistic exchange.
- $-65\text{ dBm} \ge \text{RSSI} \ge -85\text{ dBm}$: Medium Range (5m – 25m) — Critical and High priority packets only.
- $\text{RSSI} < -85\text{ dBm}$: Fringe Range (> 25m) — Packets dropped or deferred until stronger signal acquired.

---

## 5. Radio Duty-Cycle Management

| Battery Profile | Battery % | BLE Scan Window | BLE Scan Interval | BLE Adv Interval | Wi-Fi Direct Allowed |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Normal** | $\ge 60\%$ | 300 ms | 1,000 ms | 1,000 ms | Yes |
| **Power Efficient** | $30\% - 59\%$ | 200 ms | 2,500 ms | 2,000 ms | Yes (throttled) |
| **Emergency Low Power**| $15\% - 29\%$ | 100 ms | 5,000 ms | 4,000 ms | No |
| **Critical Survival** | $< 15\%$ | 50 ms | 10,000 ms | 8,000 ms | No |
