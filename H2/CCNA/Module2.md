# 2.1 Frame Forwarding

---

## Switching in Networking ![](./_/M2_Switching.png)

* **Ingress:** Frame **entering** a switch.  
* **Egress:** Frame **exiting** a switch.  
* Forwarding decision: Based on **Ingress Interface** + **Destination MAC Address**.  
* Switch uses the **MAC Address Table (CAM table)** to find the correct egress port.  
* **Golden Rule:** A frame is **never forwarded back out** the same interface it came in on.  

---

## The Switch MAC Address Table

Switches use the **destination MAC address** to select the correct **egress interface**.  

To do this, the switch must **learn device locations** by building the MAC address table dynamically:  

* Each incoming frame provides:  
  - **Source MAC Address**  
  - **Ingress Port**  

---

## The Switch Learn and Forward Method

Switches operate in a **two-step process**:

### Step 1: Learn (Source Address)
* **New Source:** Add MAC + port mapping to the table.  
* **Existing Source:** Refresh/update its entry (reset the **aging timer**, ~5 minutes).  

### Step 2: Forward (Destination Address)
* **Known Unicast:** Forward to the specific egress port.  
* **Unknown Unicast, Broadcast, or Multicast:** **Flood** the frame to all ports **except ingress**.  

---

## Video: MAC Address Tables on Connected Switches

* **Building:** Switches **construct tables dynamically** from source MACs.  
* **Using:** Switches forward based on **destination MAC lookups**.  

---

## Switch Forwarding Methods

Switches use **ASIC hardware** for high-speed forwarding. Two main methods:

---

### 1. Store-and-Forward Switching (Cisco Preferred) ![](./_/M2_StoreForwardSwitching.png)

* **Receives the full frame** before forwarding.  
* Performs **error checking** (Frame Check Sequence).  
* **Slower latency**, but ensures **reliable, error-free forwarding**.  

---

### 2. Cut-Through Switching (Low Latency) ![](./_/M2_CutThroughSwitching.png)

* Forwards frame **as soon as destination MAC is read**.  
* **Does not wait** for the full frame.  
* **Very low latency**, but may forward **corrupted frames**.  

---

## Store-and-Forward Switching – Reliability Focus

1. **Error Checking:** Validates **FCS/CRC** before forwarding; discards bad frames.  
2. **Buffering:** Temporarily stores frame in memory, allowing support for **different port speeds**.  

---

## Cut-Through Switching – Speed Focus

* **Immediate Forwarding:** Only waits until **destination MAC** is known.  
* **Latency:** Typically under **10 microseconds**.  
* **Error Propagation:** May forward bad frames (no FCS check).  
* **Port Speeds:** Requires **same speed** on all ports.  

---

### Fragment-Free Method (Modified Cut-Through)

* Switch verifies frame is at least **64 bytes long** before forwarding.  
* Prevents forwarding of **collision fragments ("runts")**.  

# 2.2 Switching Domains

---

## Collision Domains ![](./_/M2_CollisionDomains.png)

* **Switch Role:** Breaks up collision domains, reducing **network congestion**.  
* **Full-Duplex:** Each port is its **own collision domain** → no collisions.  
* **Half-Duplex:** Ports share the medium → **collisions possible**.  
* **Default Today:** Most devices use **auto-negotiation**, usually full-duplex.  

---

## Broadcast Domains ![](./_/M2_Boradcast.png)

* **Definition:** All devices that receive the **same broadcast traffic**.  
* **Scope:** Extends across **hubs (L1)** and **switches (L2)**.  
* **Boundary:** A **router (L3)** breaks broadcast domains.  
* **Switch Behavior:** Broadcasts are **flooded out all ports** except ingress.  
* **Risk:** Too many devices = **broadcast storms** → congestion + poor performance.  

---

## Alleviated Network Congestion

Switches improve performance with:  

| Feature | Function / Benefit |
|---------|--------------------|
| **Fast Port Speeds** | Ports support very high speeds (up to 100 Gbps). |
| **Fast Internal Switching** | Uses **ASICs + internal bus/memory** for rapid transfers. |
| **Large Frame Buffers** | Stores frames temporarily, handles bursts + speed mismatches. |
| **High Port Density** | Keeps local traffic local, reduces pressure on uplinks. |