# Disaster Recovery & Field Operations Runbook

## 1. Operational Phasing

During a major disaster (cyclone, earthquake, flood, regional power grid blackout), emergency response teams execute operations in three distinct phases:

```
+-------------------------------------------------------------------------+
|                  DISASTER RECOVERY OPERATIONAL PHASES                   |
+-------------------------------------------------------------------------+

  [ Phase 1: Immediate Triage ]  (0 - 6 Hours)
   - Autonomous mesh deployment across survivors
   - Direct local SOS beaconing and life-safety triage
   - Battery duty-cycles set to PowerEfficient / EmergencyLowPower

  [ Phase 2: Mesh Courier Expansion ]  (6 - 24 Hours)
   - First responders and drone couriers bridge isolated sectors
   - Search-and-rescue teams establish staging depots
   - GPS breadcrumbs track cleared structures

  [ Phase 3: Uplink Gateway Restoral ]  (24+ Hours)
   - Satellite / mobile COW (Cell on Wheels) uplinks activated
   - Accumulated mesh sync queues uploaded to Command Center
   - Authoritative civil defense evacuation broadcasts pushed to mesh
```

---

## 2. Node Deployment Topology in the Field

### 1. Static Shelter / Staging Relay Nodes
- Place phones or dedicated low-power Android relay tablets connected to solar battery banks on high ground, shelter rooftops, or church bell towers.
- Configure these nodes to **Continuous Scanning Mode** with Wi-Fi Direct enabled.
- Act as high-capacity message deposit boxes (couriers drop packets as they pass by).

### 2. Mobile Courier Relays
- Rescue vehicles, paramedic ambulances, and patrol boats carry devices running Emergixx.
- As they travel between isolated evacuation zones, their encounter memory automatically collects new SOS alerts and delivers acknowledgments.

---

## 3. Battery Preservation Protocol for Survivors

1. **Lock Screen Immediately After Sending SOS**: The foreground service will continue beaconing in the background.
2. **Activate High-Contrast Emergency Mode**: Reduces AMOLED display power consumption by up to 60%.
3. **Turn Off Unnecessary Sensors**: Keep Bluetooth ON. Turn off Wi-Fi if battery is under 15%. GPS should be queried periodically rather than continuously.
