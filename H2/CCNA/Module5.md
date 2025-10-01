# 5.1 Purpose of STP

## Redundancy in Layer 2 Networks
- **Goal:** Backup paths to prevent **single points of failure**  
- Ensures access to resources even if a path fails  
- **Types of redundancy:**  
  - Physical: Extra cables/links  
  - Logical: Smart design to prevent loops  

- **Problem:** Extra paths create **Layer 2 loops**  
  - Loops = frames circulate endlessly → network disruption  

- **Solution:** **STP (Spanning Tree Protocol)** → loop-free logical network with redundancy

## Spanning Tree Protocol (STP)
- **STP:** Loop-prevention for Layer 2  
- **Purpose:** Keep network **loop-free** while allowing redundancy  
- **Function:**  
  - Blocks loops logically  
  - Prevents endless frame circulation  

## STP Recalculation
- **On failure:** STP recalculates topology  
- Previously blocked ports may **open** to restore connectivity  
- Maintains **loop-free operation** and redundancy  

## Issues Without STP
- Multiple paths → **Layer 2 loops**  
- Effects:  
  - MAC table instability  
  - Link saturation  
  - High CPU usage  
  - Network unusable  

- **Reason:**  
  - Ethernet cannot stop looping frames  
  - Layer 3 uses TTL/Hop Limit, but Layer 2 cannot  

- **Prevention:** **Enable STP**

## Layer 2 Loops & Broadcast Storms
- **Loops:** Broadcast, multicast, unknown unicast frames circulate endlessly  
- **Effects:** MAC table instability, CPU overload, forwarding fails  
- **Broadcast storm causes:** Faulty NIC, Layer 2 loops  
- **Traffic examples:** ARP Requests, Layer 2 multicasts, IPv6 neighbor discovery  
- **Solution:** **STP enabled by default**

## Spanning Tree Algorithm (STA)
- Invented by **Radia Perlman (1985)**  
- **Purpose:** Create loop-free Layer 2 topology  

### STA Steps
1. **Select Root Bridge:** One switch = reference, others build spanning tree  
2. **Block Redundant Paths:** Blocked ports do not forward traffic  
3. **Create Loop-Free Topology:** One logical path per switch → tree topology  
4. **Recalculate on Failure:** Backup paths unblocked if primary fails or new switch/link added

# 5.2 STP Operations

## Steps to a Loop-Free Topology
STP uses **Spanning Tree Algorithm (STA)** to prevent loops in 4 main steps:

1. **Elect Root Bridge** – Switch that becomes **network reference point**  
2. **Elect Root Ports** – Closest port to root bridge on non-root switches  
3. **Elect Designated Ports** – Ports that **forward traffic toward root**  
4. **Elect Alternate (Blocked) Ports** – Remaining ports blocked as **backup paths**

## Role of BPDUs
- **BPDUs (Bridge Protocol Data Units):** Share network topology info  
- Used to elect: Root bridge, Root ports, Designated ports, Alternate ports

## Bridge ID (BID)
- Identifies a switch in BPDU  
- Components: Priority, MAC address, Extended system ID  
- **Lowest BID** wins → becomes root and determines port roles

### Bridge Priority & MAC
- Priority default: 32768 (range 0–61440, increments 4096)  
- Lower = better  
- Extended System ID identifies VLAN  
- If priority & system ID equal → **lowest MAC wins**

## Root Bridge Election
- Switches exchange **BPDUs every 2 sec**  
- Initially, all consider themselves root  
- **Lowest BID** becomes root bridge  
- Admin tip: Set desired root with **lower priority**

## Root Path Cost
- Path cost = sum of all port costs along path to root  
- Switch adds **its segment port cost** when receiving BPDU

### Default Port Costs
| Link Speed | STP Cost | RSTP Cost |
|-----------|----------|-----------|
| 10 Gbps  | 2        | 2000      |
| 1 Gbps   | 4        | 20,000    |
| 100 Mbps | 19       | 200,000   |
| 10 Mbps  | 100      | 2,000,000 |

- Port costs are **configurable** for preferred paths

## Root Ports
- **Root port:** Closest port to root bridge on a non-root switch  
- Selected based on **lowest path cost**  
- Redundant paths **blocked**

### Example
- S2 → root S1  
  - Path 1 cost = 19 → chosen  
  - Path 2 cost = 38 → blocked

## Designated Ports
- **Designated port:** Best port on segment forwarding to root  
- Rules:  
  - All ports on root = designated  
  - Segment between switches → port with **lowest cost**  
  - End-device ports automatically designated

## Alternate (Blocked) Ports
- Ports **not root or designated**  
- **Blocking state** prevents loops  
- Example: Port F0/2 blocked, others forwarding

## Elect Root Port from Equal-Cost Paths
1. Lowest sender BID  
2. Lowest sender port priority  
3. Lowest sender port ID

## STP Timers
- **Hello Timer:** BPDU interval (default 2s)  
- **Forward Delay:** Time in listening/learning before forwarding (default 15s)  
- **Max Age:** Max time before topology change (default 20s)  
> Timers set by root bridge

## STP Port States
- **Blocking:** Prevent loops, receive BPDU only  
- **Listening:** Learns topology, does not forward  
- **Learning:** Updates MAC table, no forwarding  
- **Forwarding:** Forwards frames, learns MAC  
- **Disabled:** Admin down, non-operational

| Port State | BPDU | MAC Table | Forwarding |
|------------|------|-----------|------------|
| Blocking   | Receive | No update | No |
| Listening  | Send/Receive | No update | No |
| Learning   | Send/Receive | Updating | No |
| Forwarding | Send/Receive | Updating | Yes |
| Disabled   | None | No update | No |

## Per-VLAN Spanning Tree (PVST)
- Separate STP instance for each VLAN  
- Example: VLAN 1 → 1 root bridge, 1 spanning tree instance

# 5.3 Evolution of STP

## STP Versions
- **STP (802.1D)** – Original IEEE standard, one spanning tree for all VLANs  
- **RSTP (802.1w)** – Faster convergence, backward compatible with STP  
- **PVST+** – Cisco STP per VLAN, supports PortFast, BPDU Guard, Loop Guard  
- **Rapid PVST** – Cisco RSTP per VLAN, fast per-VLAN convergence  
- **MSTP (802.1s)** – Maps multiple VLANs to same spanning tree  
- **Cisco MST** – Up to 16 RSTP instances, VLANs combined per topology  

## Cisco Implementations
- Default: **PVST+** on IOS 15+  
- Supports **alternate ports** instead of old non-designated ports  
- **Rapid PVST+** runs RSTP per VLAN → fast convergence  
- RSTP must be explicitly enabled

## RSTP Concepts
- Replaces STP, faster convergence  
- Maintains **port roles** and **algorithm similar to STP**  
- Converges in **hundreds of milliseconds** if network configured well

### Port States
- **Discarding** → combines disabled, blocking, listening  
- **Learning** → learns MAC addresses, no forwarding  
- **Forwarding** → forwards frames, learns MAC addresses

### Port Roles
- **Root Port** – Closest port to root  
- **Designated Port** – Best port to forward toward root  
- **Alternate Port** – Backup path to root, can immediately forward  
- **Backup Port** – Rare, used for shared medium (legacy hubs)

## PortFast and BPDU Guard
### PortFast
- Skips **Listening + Learning**, goes **directly to Forwarding**  
- Use only on **access ports**, not switch-to-switch  
- Prevents DHCP delays

### BPDU Guard
- Protects **PortFast ports** from loops  
- If BPDU received → port goes **err-disabled**  
- Admin must manually re-enable

## Alternatives to STP
- Large Layer 2 networks → **hundreds of switches/VLANs**  
- **RSTP & MSTP** handle redundancy and complexity  
- Convergence slower than Layer 3 routing  
- Layer 3 routing between access/distribution → redundant paths without blocked ports  
- Only **access layer** remains pure Layer 2
