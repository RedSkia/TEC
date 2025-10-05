# 11.1 Implement Port Security

---

## Basic Defense: Securing Unused Ports

### Why Secure Layer 2?
* **Layer 2 attacks** (like **MAC flooding**) are easy for hackers.
* Basic security easily stops these threats.
* **All switch ports** must be secured **before use**.

### Disabling Unused Ports (Basic Security)
* The **simplest security** is to **disable all unused ports** to block unauthorized physical access.

| Action | Command | Purpose |
| :--- | :--- | :--- |
| **Disable Port** | `Switch(config-if)# shutdown` | Immediately turns off a port. |
| **Re-Enable Port** | `Switch(config-if)# no shutdown` | Turns a disabled port back on. |
| **Config Many Ports** | `Switch(config)# interface range type module/first-number - last-number` | Apply one command to a group of ports. |

---

## Mitigating MAC Address Table Attacks

### Port Security Overview
* **Port Security** is the best defense against **MAC address table overflow attacks**.
* It strictly **limits the number of MAC addresses** allowed on a single switch port.

### How Port Security Works
1. **Limit:** An admin sets the **maximum** number of allowed MAC addresses (default is **1**).
2. **Learning:** Secure MACs are added either **Manually** (static) or **Dynamically** (learned).
3. **Control:** Limiting the MAC count blocks unauthorized devices and prevents the MAC table from being filled with fake addresses.

---

## Configuration and Enablement

### Requirements for Port Security
* The Port Security command is **rejected** if the port is in its default dynamic trunking state.
* **Port Security ONLY works** if the port is manually set as an **Access Port** or a **Trunk Port**.

### Cisco IOS Enablement Steps
| Step | Command |
| :--- | :--- |
| 1. **Set Port Mode** (Required) | `Switch(config-if)# switchport mode access` |
| 2. **Enable Port Security** | `Switch(config-if)# switchport port-security` |

### Default Settings
When enabled, the switch automatically uses these settings:

| Setting | Default Value | Violation Result |
| :--- | :--- | :--- |
| **Maximum MACs** | **1** | Only one device is allowed. |
| **Violation Mode** | **Shutdown** | Port enters **error-disabled** state (shuts down). |

### Important Note
* If a single device is connected, the switch learns its MAC and secures it (since the limit is 1).
* **Warning:** If multiple devices are active on the port when you enable Port Security, the port will immediately shut down (enter the **error-disabled** state).

---

## Limiting and Learning MAC Addresses

### Setting the Maximum Limit
* Use the **`maximum`** command to control the total number of allowed secure MAC addresses.
```
Switch(config-if)# switchport port-security maximum [value]
```

### Three MAC Address Learning Methods

| Method | Command | Persistence (After Reboot) | Keyword |
| :--- | :--- | :--- | :--- |
| 1. **Manually Configured** (Static) | `switchport port-security mac-address [mac-address]` | **Permanent** (saved in running-config). | **Static** |
| 2. **Dynamically Learned** | (Default - no command) | **Lost**; must be re-learned. | **Dynamic** |
| 3. **Dynamically Learned — Sticky** | `switchport port-security mac-address sticky` | Learned MACs are saved to the running-config. **Persists** across reboots *if* you save the running-config. | **Sticky** |

### Complete Configuration Example
Sets the max limit to 4, adds one permanent MAC, and enables sticky learning for the remaining 3 slots:
```
Switch(config-if)# switchport port-security maximum 4
Switch(config-if)# switchport port-security mac-address AAAA.BBBB.CCCC
Switch(config-if)# switchport port-security mac-address sticky
```

---

## Port Security Aging

### Overview
* **Aging** automatically **removes secure MAC addresses** after a set time.
* This is more flexible than manual deletion.
* It works for static (if enabled) and dynamic addresses.

### Two Types of Aging
| Aging Type | Action | Keyword |
| :--- | :--- | :--- |
| **Absolute** | MAC is deleted after a **fixed time**, *regardless* of traffic. | **Fixed time** |
| **Inactivity** | MAC is deleted *only if* **no traffic** is seen for the set time. | **No traffic** |

### Cisco IOS Aging Commands
```
Switch(config-if)# switchport port-security aging time [value]
Switch(config-if)# switchport port-security aging type {absolute | inactivity}
```

* **Example:** Set inactivity aging for 10 minutes:
* `Switch(config-if)# switchport port-security aging time 10`
* `Switch(config-if)# switchport port-security aging type inactivity`

---

## Port Security Violation Modes

### Overview
A violation occurs when an unauthorized MAC tries to connect. The mode sets the switch's immediate response.

### Configuration Command
```
Switch(config-if)# switchport port-security violation {shutdown | restrict | protect}
```

### Violation Modes Explained
| Mode | Security Level | Action and Result | Keyword |
| :--- | :--- | :--- | :--- |
| **Shutdown (Default)** | **Highest** | **Shuts down** the port (**error-disabled** state). Needs manual recovery (`shutdown`/`no shutdown`). Sends a log message. | **Shutdown** |
| **Restrict** | **Medium** | **Drops** unauthorized packets. Port stays up. Sends a log message and counts the violation. | **Restrict** |
| **Protect** | **Lowest** | **Drops** unauthorized packets. Port stays up. **DOES NOT** send a log message or count the violation (**silent blocking**). | **Protect** |

### Ports in Error-Disabled State
* An **error-disabled** port is fully shut down and cannot pass traffic.
* **Manual Recovery:** An admin must re-enable it with:
```
Switch(config-if)# shutdown
Switch(config-if)# no shutdown
```

---

## Verification Commands

| Command | Purpose | Key Details Displayed | Keyword |
| :--- | :--- | :--- | :--- |
| `Switch# show port-security` | **Global Summary:** Quick overview of all ports. | Max Addr, Current Addr, Violation Mode, Security Status. | **Summary** |
| `Switch# show port-security interface [id]` | **Detailed View:** Specific configuration and status for one port. | Violation Count, Aging Type/Time, Sticky status. | **Interface** |
| `Switch# show port-security address` | **Secure MAC Address List:** Shows all secure MACs. | MAC Address, Learning Type (Static/Dynamic/Sticky), VLAN, and Port. | **MAC Address** |










































# 11.2 Mitigate VLAN Attacks

---

## VLAN Hopping Attacks: Methods and Review

**VLAN Hopping** is an attack where an attacker on one VLAN can **access traffic on other VLANs** without a router. It is a way to bypass Layer 2 security.

### Attack Methods

| Attack Method | Simple Explanation | Defense Keyword |
| :--- | :--- | :--- |
| **DTP Spoofing** | Attacker fakes **DTP (Dynamic Trunking Protocol)** messages to trick the switch into creating an unauthorized **trunk link**. | **DTP** |
| **Rogue Switch** | Attacker connects their own **rogue switch** and enables trunking, giving them access to **all VLANs** on the victim switch. | **Trunking** |
| **Double-Tagging** | Attacker sends a frame with **two VLAN tags** to sneak traffic past the switch and into a restricted **target VLAN**. | **Native VLAN** |

---

## Steps to Stop VLAN Hopping Attacks

VLAN hopping is prevented by manually securing the switch's **trunking** configuration.

| Step | Action and Purpose | Cisco IOS Command | Key Defense Principle |
| :--- | :--- | :--- | :--- |
| **1. Secure User Ports** | **Disable DTP** on all ports connected to end-user devices (non-trunk ports). This prevents **DTP Spoofing**. | `switchport mode access` | **Force access mode.** |
| **2. Secure Unused Ports** | **Shut down** unused ports and move them to an **unused VLAN**. This reduces the attack surface. | `shutdown` and `switchport access vlan [unused_vlan_id]` | **Isolate and disable.** |
| **3. Manually Enable Trunk** | **Explicitly set** ports that *must* be trunks to trunk mode. Trunk links should be created by design, not by negotiation. | `switchport mode trunk` | **No negotiation for trunks.** |
| **4. Disable DTP on Trunk** | **Completely disable DTP negotiation** even on designated trunk ports. This provides maximum security. | `switchport nonegotiate` | **Disable DTP entirely.** |
| **5. Change Native VLAN** | Set the **Native VLAN** on trunks to an unused VLAN ID **other than the default VLAN 1**. This stops **Double-Tagging Attacks**. | `switchport trunk native vlan [vlan_number]` | **Move Native VLAN.** |
















# 11.3 Mitigate DHCP Attacks

---

## DHCP Attacks Review and Defense

### DHCP Starvation Attack
* **Goal:** Create a **Denial of Service (DoS)** by taking all available IP addresses in the pool.
* **Method:** Attacker sends thousands of rapid **DHCP requests** using fake MAC addresses, leasing every IP.
* **Defense Keyword:** **Port Security** can help by limiting the total number of MAC addresses allowed per port.

### DHCP Spoofing Attack
* **Goal:** Set up a **rogue DHCP server** to give clients false network settings (like a malicious default gateway).
* **Problem:** Attackers can bypass Port Security by using a legitimate MAC address on the frame but a **bogus MAC address** inside the DHCP data.
* **Primary Defense:** **DHCP Snooping** on trusted ports is the only effective solution.

---

## DHCP Snooping: The Core Defense

### Function and Goals
* **DHCP Snooping** is a Layer 2 security feature that filters DHCP messages.
* It is the primary defense against **rogue DHCP servers** (spoofing) and also helps against **DHCP starvation attacks** (via rate limiting).

### Trusted vs. Untrusted Ports
DHCP Snooping works by creating a clear security boundary:

| Port Type | Definition | Configuration | What the Switch Does | Keyword |
| :--- | :--- | :--- | :--- | :--- |
| **Trusted** | Ports connected to **legitimate DHCP servers** or other trusted switches/routers. | **Must be explicitly configured** as trusted. | Allows **all** DHCP messages (including Server Replies). | **Server** |
| **Untrusted** | All other ports, typically connected to **client devices**. | Default setting. | **Blocks** DHCP Server messages (Offers/ACKs) to stop rogue servers. | **Client** |

### The DHCP Snooping Binding Table
* When a client gets a valid IP from the legitimate DHCP server, Snooping records: the client's **MAC address**, the **assigned IP address**, and the **switch port**.
* This **Binding Table** ensures the client can only use that specific IP/MAC combination on that port.
* The table is critical for other security features like **Dynamic ARP Inspection (DAI)**.

---

## Steps to Implement DHCP Snooping

| Step | Location | Goal | Command |
| :--- | :--- | :--- | :--- |
| **1** | Global Config | Enable DHCP Snooping globally. | `ip dhcp snooping` |
| **2** | Global Config | Enable for specific VLANs to process traffic. | `ip dhcp snooping vlan [vlan-ID/range]` |
| **3** | Interface Config | Identify the **trusted** port (connected to the DHCP server). | `ip dhcp snooping trust` |
| **4** | Interface Config | Limit DHCP traffic rate on **untrusted** ports (to fight starvation). | `ip dhcp snooping limit rate [pps]` |

### CLI Example
```text
S1(config)# ip dhcp snooping
S1(config)# ip dhcp snooping vlan 5,10
S1(config)# interface [Upstream Interface]
S1(config-if)# ip dhcp snooping trust
S1(config-if)# exit
S1(config)# interface range F0/15-24
S1(config-if-range)# ip dhcp snooping limit rate 6
```



## Verification Commands

| Command | Goal | What it Shows | Keyword |
| :--- | :--- | :--- | :--- |
| `show ip dhcp snooping` | Verify settings | Global status, active VLANs, and trusted/untrusted ports. | **Status** |
| `show ip dhcp snooping binding` | Verify clients | Lists the **MAC/IP** bindings, lease time, and port. | **Binding Table** |

---

## Relationship with DAI

* **DHCP Snooping is required for Dynamic ARP Inspection (DAI).**
* DAI uses the **DHCP Snooping Binding Table** to confirm that the IP and MAC addresses in an **ARP packet** are valid.
* If the IP/MAC addresses don't match the table, the ARP packet is **dropped**.










# 11.4 Mitigate ARP Attacks

---

## Dynamic ARP Inspection (DAI)

In a typical **ARP attack** (like **ARP spoofing** or **ARP poisoning**), an attacker sends fake ARP replies, often using the **attacker's MAC address** with the **IP address of the default gateway**.

**Dynamic ARP Inspection (DAI)** is the switch feature that prevents these attacks by ensuring only valid ARP messages are relayed.

### How DAI Prevents ARP Attacks
* **Requires DHCP Snooping** to work, as it uses the **DHCP Snooping Binding Table** to verify IP-to-MAC pairings.
* **Intercepts all ARP Requests and Replies** on untrusted ports.
* **Verifies** each packet against a valid **IP-to-MAC binding**.
* **Drops and logs** invalid ARP Replies.
* **Does not relay** invalid or gratuitous ARP Replies.
* **Error-disables the interface** if the rate limit for ARP packets is exceeded.

---

## DAI Implementation Guidelines

To reduce the risk of **ARP spoofing** and **ARP poisoning**, follow these DAI implementation guidelines:

1.  **Enable DHCP Snooping** globally (`ip dhcp snooping`).
2.  **Enable DHCP Snooping** on selected VLANs (`ip dhcp snooping vlan [vlan-ID]`).
3.  **Enable DAI** on selected VLANs (`ip arp inspection vlan [vlan-ID]`).
4.  **Configure trusted interfaces** for both DHCP Snooping and DAI (e.g., uplink ports connected to routers or other secure switches).

### Best Practice for Ports
* Configure all **access switch ports** (client-facing) as **untrusted**.
* Configure all **uplink ports** (switch-to-switch/router) as **trusted**.

---

## DAI Configuration and Validation

### DAI Validation Checks
DAI can be configured to check three parts of an ARP packet for validity:

| Check | Focus | Validation Detail |
| :--- | :--- | :--- |
| **Destination MAC** | Ethernet Header | Checks the **destination MAC** in the Ethernet header against the **target MAC** in the ARP body. |
| **Source MAC** | Ethernet Header | Checks the **source MAC** in the Ethernet header against the **sender MAC** in the ARP body. |
| **IP Address** | ARP Body | Checks the ARP body for **invalid or unexpected IP addresses**, like `0.0.0.0`, `255.255.255.255`, and **IP multicast addresses**. |

### DAI Validation Command

The command used to configure DAI to drop ARP packets based on these checks is:

```text
ip arp inspection validate {src-mac | dst-mac | ip}
```


* This command is used to drop ARP packets when **IP addresses are invalid** or when **MAC addresses** in the ARP body do not match the Ethernet header.
* **Crucial Note:** To include **more than one validation method** (e.g., both source MAC and IP), specify all options on the **same command line**. Entering the command multiple times **overwrites** the previous configuration.


















# 11.5 Mitigate STP Attacks

---

## PortFast and BPDU Guard: The Defense

Network attackers can manipulate the **Spanning Tree Protocol (STP)** to spoof the root bridge and change the network topology. To stop this, use **PortFast** and **BPDU Guard**.

| Feature | Primary Purpose | Action | Where to Use | Keyword |
| :--- | :--- | :--- | :--- | :--- |
| **PortFast** | Speeds up port access. | Immediately moves the port to the **forwarding state**, skipping the listening and learning states. | **All end-user access ports**. | **Speed** |
| **BPDU Guard** | Prevents rogue switches. | Immediately puts the port into the **error-disabled state** if it receives a **BPDU**. | **Only end-user access ports**. | **Stop BPDUs** |

---

## Configure PortFast

### Key Function
* **PortFast** minimizes the time access ports wait for STP to converge, improving user access speed.
* **Only enable PortFast on access ports.**
* **Warning:** Enabling PortFast on inter-switch links (trunk ports) can create a **spanning-tree loop**.

### How to Enable PortFast
* **On a specific interface:**
  ```text
  Switch(config-if)# spanning-tree portfast enable
  ```

  ### How to Enable PortFast (Continued)

* **Globally (for all access ports that are not trunking):**
    ```text
    Switch(config)# spanning-tree portfast default
    ```

---

### Verify PortFast Configuration

| Command | Goal | Keyword |
| :--- | :--- | :--- |
| `show running-config | begin spanning-tree` | Verify global settings in the running config. | **Global Config** |
| `show spanning-tree summary` | Verify global PortFast status. | **Summary Status** |
| `show running-config interface [type/number]` | Verify PortFast status on a specific interface. | **Interface Config** |
| `show spanning-tree interface [type/number] detail` | Verify detailed STP status for a specific interface. | **Interface Detail** |

---

## Configure BPDU Guard

### Key Function
* An access port should **never receive a BPDU**. Receiving one means a user either **accidentally** or **maliciously** connected an unauthorized switch.
* If a **BPDU** is received on a BPDU Guard-enabled port, the port immediately enters the **error-disabled state** (shut down).

### Recovery
* A port in the **error-disabled state** must be **manually re-enabled** (using `shutdown` then `no shutdown`) unless automatic recovery is configured:
    ```text
    errdisable recovery cause psecure-violation
    ```

### How to Enable BPDU Guard
* **On a specific interface:**
    ```text
    Switch(config-if)# spanning-tree bpduguard enable
    ```
* **Globally (on all ports where PortFast is enabled):**
    ```text
    Switch(config)# spanning-tree portfast bpduguard default
    ```