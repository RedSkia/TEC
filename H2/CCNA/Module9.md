# 9.1 First Hop Redundancy Protocols

## Default Gateway Limitations
- Devices usually have **one default gateway** (a router IP).  
- If that gateway fails → devices **cannot access networks outside the LAN**.  
- Even if another router is available, devices **won’t switch automatically**.  

## First Hop Redundancy Protocols (FHRPs)
- FHRPs solve this problem by creating a **virtual gateway** shared by multiple routers.  
- If the active router fails → another router **automatically takes over**.  
- Ensures **continuous network access** without manual changes.  

## Router Redundancy

### Why Router Redundancy?
- Prevents LAN-wide connectivity loss if the default gateway fails.  
- Achieved using a **virtual router** (multiple routers acting as one).  

### How It Works
- Routers share:
  - **One IP address** (default gateway for hosts).  
  - **One MAC address** (hosts always know where to send traffic).  
- Hosts send traffic to the **virtual IP/MAC**, and the **active router forwards it**.  

### What Hosts See
- Hosts only see the **virtual router**.  
- Frames are sent to the virtual MAC; the **active router handles them**.  

### Behind the Scenes
- A **protocol decides which router is active**.  
- If active router fails, a standby router **takes over instantly**.  
- **No disruption** is visible to hosts.  

### Role of a Redundancy Protocol
- Determines:
  - Which router is **active** (forwards traffic).  
  - Which routers are **standby** (ready to take over).  

### Smooth Transition
- If active router fails → **standby router automatically takes over**.  
- **Transparent to end devices**.  

### Key Term
- **First-Hop Redundancy**: Ability of the network to **recover automatically** when the default gateway fails.  

## Steps for Router Failover
1. **Standby router notices** it is no longer receiving "Hello" messages from active router.  
2. **Standby router takes over** as the new active router.  
3. New active router uses **same IP and MAC** → hosts see **no change**.  

✅ Result: Traffic continues **without disruption**.  

## FHRP Options

| Protocol | Type | IPv4 / IPv6 | Key Features |
|----------|------|-------------|--------------|
| **HSRP** | Cisco proprietary | IPv4 | Failover. One active router forwards traffic; standby takes over if active fails. |
| **HSRP for IPv6** | Cisco proprietary | IPv6 | Same as HSRP, but for IPv6. Uses virtual MAC + IPv6 link-local address. Sends RAs when active. |
| **VRRPv2** | Open standard | IPv4 | Multi-vendor support. One master; backups take over if master fails. |
| **VRRPv3** | Open standard | IPv4 & IPv6 | Supports IPv4 & IPv6. More scalable; works in multi-vendor environments. |
| **GLBP** | Cisco proprietary | IPv4 | Redundancy + load balancing. Multiple routers can share traffic. |
| **GLBP for IPv6** | Cisco proprietary | IPv6 | Same as GLBP but for IPv6. Supports backup and load sharing. |
| **IRDP** | Open standard (RFC 1256) | IPv4 | Legacy. Hosts can discover routers for remote networks. Rarely used. |


# 9.2 HSRP

## HSRP Overview
- **HSRP (Hot Standby Router Protocol)** is Cisco proprietary.  
- Prevents loss of outside network access if default router fails.  
- Provides **transparent failover** → hosts don’t notice.  
- Ensures **high availability** with a backup gateway.  

## How It Works
- Routers form an **HSRP group**.  
- Roles:
  - **Active router** = forwards packets.  
  - **Standby router** = monitors active router and takes over if needed.  

## Key Point
- **Standby router watches active router** and **takes over immediately** if active fails.  

## HSRP Priority and Preemption

### Election Process
- Active vs standby chosen based on:
  1. **HSRP Priority** (higher wins).  
  2. If equal → router with **highest IPv4 address** wins.  

### Default Settings
- Default **priority** = 100.  
- Range: 0–255.  

### Configuring Priority
- Command: `standby priority <value>`  
- Set higher priority for the router you want as **active**.  

### Why It Matters
- Lets you **control which router becomes active**.  

### Default Behavior
- Active router **remains active** even if a higher-priority router comes online.  

### Preemption
- Allows **higher-priority router to take over**.  
- Enable: `standby preempt`  
- Rules:
  - Only routers with **higher priority** can preempt.  
  - Equal priority + higher IP **does not preempt**.  

### Without Preemption
- **First router to boot** becomes active if no other routers are online.  
- Higher-priority routers **won’t take over** unless preemption is enabled.  

## HSRP States and Timers

### HSRP States

| State   | Description |
|---------|-------------|
| **Initial** | Router just started or interface up. **Does not know virtual IP**; listens for hello messages. |
| **Learn**   | Knows virtual IP, but not active/standby. Listens for hello messages. |
| **Listen**  | Listens and participates in HSRP election. |
| **Speak**   | Sends hello messages; can become active/standby. |
| **Standby** | Ready to take over if active fails. |

### HSRP Timers
- **Hello Timer**: Send hello every 3 sec (default).  
- **Hold Timer**: Standby becomes active if no hello for 10 sec (default).  

#### Notes
- Adjust timers for faster failover:
  - Min hello timer: 1 sec  
  - Min hold timer: 4 sec  
- Too low → higher CPU usage & unnecessary state changes.  
