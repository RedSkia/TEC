# 4.1 Inter-VLAN Routing Operation (![](./_/M4_InterVlanRoute.png))

---

## What is Inter-VLAN Routing?
- **VLAN Segmentation:** Divides a Layer 2 network into separate broadcast domains  
- **Communication Barrier:** Hosts in different VLANs **cannot communicate directly**  
- **Definition:** Forwarding traffic **between VLANs** using a router or Layer 3 switch

---

## Inter-VLAN Routing Methods

1. **Legacy Inter-VLAN Routing**
   - **Uses:** One physical router interface per VLAN  
   - **Scaling:** Not scalable, uses many ports, high cost

2. **Router-on-a-Stick**
   - **Uses:** Single router interface with **subinterfaces** per VLAN  
   - **Connection:** Router connects to a switch trunk port  
   - **Scaling:** Suitable for small/medium networks

3. **Layer 3 Switch with SVIs**
   - **Uses:** Layer 3 switch with **Switched Virtual Interfaces (SVIs)** per VLAN  
   - **Routing:** Switch routes internally between VLANs  
   - **Scaling:** Best for medium/large networks

---

## Legacy Inter-VLAN Routing Details
- **Method:** Router with multiple physical Ethernet interfaces  
- **Connection:** Each router interface links to one VLAN via switch port  
- **Role:** Acts as **default gateway** for VLAN subnet  

---

## Limitations of Legacy Method
- **Not Scalable:** One interface per VLAN quickly exhausts router ports  
- **Obsolete:** Modern networks prefer **Router-on-a-Stick** or **Layer 3 Switch SVIs**

# 4.2 Router-on-a-Stick Inter-VLAN Routing (![](./_/M4_RouterStick.png))

---

## Overview
- **Router-on-a-Stick:** Routes multiple VLANs using **one physical router interface**  
- **Purpose:** Overcomes port limitations of legacy inter-VLAN routing  
- **Connection:** Router interface → switch **trunk port**  
- **Subinterfaces:** Logical divisions of physical interface, one per VLAN  
  - Each subinterface has **VLAN ID** and **IP address** (default gateway)  
  - Use command: `encapsulation dot1q [vlan-id]` to assign VLAN tag  

---

## How Traffic is Routed
1. **Ingress:** VLAN-tagged frames arrive on router's physical interface  
2. **Mapping:** Router forwards traffic to the correct **subinterface** based on VLAN tag  
3. **Routing Decision:** Router checks **destination IP**  
4. **Egress:** Router **re-tags frame** with destination VLAN ID if sending back to switch  

> **Note:** Efficient for small/medium networks; **high CPU overhead** limits scaling beyond ~50 VLANs

# 4.3 Inter-VLAN Routing on a Layer 3 Switch (![](./_/M4_VlanLayer3Switch.png))

---

## Switched Virtual Interface (SVI)
- **Definition:** Virtual interface on a Layer 3 switch providing **Layer 3 processing** for a VLAN  
- **Function:** Acts as **default gateway** for devices in that VLAN  
- **Routing:** Internal; traffic **does not leave the switch**

---

## Layer 3 Switch
- **Also called:** Multilayer switch (Layer 2 + Layer 3)  
- **Scaling:** SVIs allow **highly scalable** internal routing  
- **Hardware-based:** Uses ASICs for fast packet forwarding  

---

## Inter-VLAN Routing on Layer 3 Switch
- **SVI per VLAN:** Each VLAN requiring routing has its own SVI  
- **Layer 3 Processing:** Handles packets **to/from VLAN ports** internally, no external router required  

---

## Advantages
- **High speed:** Hardware-based routing  
- **No external links** needed  
- **Scalable:** Combine multiple **EtherChannels** for trunk bandwidth  
- **Low latency:** Traffic remains inside switch fabric  
- **Common use:** Campus LAN cores  

---

## Disadvantage
- **Cost:** Layer 3 switches are generally **more expensive** than Layer 2 switches

# 4.4 Troubleshoot Inter-VLAN Routing

## Common Inter-VLAN Issues

Inter-VLAN connectivity problems are usually related to network **connectivity issues**. Before troubleshooting, always check the **physical layer** to ensure cables are connected to the correct ports.  

If physical connections are correct, the following table summarizes common reasons why inter-VLAN communication may fail and how to fix them.

| Issue Type | How to Fix | How to Verify |
|-----------|------------|---------------|
| **Missing VLANs** | Create or re-create the VLAN if it does not exist. Assign host ports to the correct VLAN. Ensure trunks are configured correctly. | `show vlan [brief]`<br>`show interfaces switchport` |
| **Switch Trunk Port Issues** | Ensure the port is a **trunk port** and enabled. Assign correct VLANs to access ports. | `show interface trunk`<br>`show running-config` |
| **Switch Access Port Issues** | Ensure the port is an **access port** and enabled. Verify host is configured in the correct subnet. | `show interfaces switchport`<br>`ipconfig` |
| **Router Configuration Issues** | Make sure router subinterface is assigned to the correct VLAN and configured with the correct IPv4 address. | `show running-config interface`<br>`show ip interface brief`<br>`ping` |

---

## Tips

* Always start troubleshooting from the **physical layer** and move upward.
* Verify **VLAN assignments** on both switches and hosts.
* Check **router subinterfaces** and IP addressing.
* Use the commands listed in the table to verify configuration and connectivity.


## Troubleshoot Inter-VLAN Routing Scenario (![](./_/M4_TroubleshootVlanRoute.png))

Examples of some of these inter-VLAN routing problems will now be covered in more detail.  
This topology will be used for all of these issues.

## Router RI Subinterfaces

| Subinterface   | VLAN | IP Address        |
|----------------|------|-----------------|
| G0/0/0.10      | 10   | 192.168.10.1/24 |
| G0/0/0.20      | 20   | 192.168.20.1/24 |
| G0/0/0.30      | 99   | 192.168.99.1/24 |


## Missing VLANs

An inter-VLAN connectivity issue could be caused by a **missing VLAN**. The VLAN could be missing if:

* It was **not created**.
* It was **accidentally deleted**.
* It is **not allowed on the trunk link**.

**Important:** When a VLAN is deleted, any ports assigned to that VLAN become **inactive**. These ports remain associated with the VLAN (and inactive) until you either:

* Assign them to a **new VLAN**, or  
* **Recreate the missing VLAN**. Recreating the VLAN automatically reassigns the hosts to it.

**Verification:** Use the following command to check VLAN membership of a port:

```bash
show interface [interface-id] switchport
```

## Switch Trunk Port Issues

Another issue for inter-VLAN routing includes **misconfigured switch ports**. 

- In a **legacy inter-VLAN solution**, this could happen if the connecting **router port** is not assigned to the correct VLAN.  
- In a **Router-on-a-Stick solution**, the most common cause is a **misconfigured trunk port**.

**Verification Steps:**

1. Ensure the port connecting to the router is correctly configured as a **trunk link**:

```bash
show interface trunk
show running-config interface [interface-id]
```

## Switch Access Port Issues

- **Problem:** Access port misconfiguration can prevent VLAN connectivity.
- **Symptom:** PC has correct IP, subnet mask, and gateway but cannot ping the gateway.
- **Verification Commands:**
  - `show vlan brief` → check VLANs
  - `show interface [X] switchport` → check port VLAN assignment
  - `show running-config interface [X]` → see port config


## Router Configuration Issues

- **Problem:** Router-on-a-stick subinterfaces may be misconfigured.
- **Verification:**
  - `show ip interface brief` → check subinterface status
  - `show interfaces` → see VLAN assignments  
    *Tip:* Use filters like `| include Gig` or `| include 802.1Q` to reduce output and focus on relevant info.