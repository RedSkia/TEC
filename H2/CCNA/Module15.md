# 15.1 Static Routes

## Types of Static Routes
Static routes are used to manually define paths in a network, even when a dynamic routing protocol is running.  
They can be configured for **IPv4** and **IPv6**.

**Types of static routes:**
- **Standard static route**  
- **Default static route**  
- **Floating static route**  
- **Summary static route**

**Configuration commands:**
- IPv4: `ip route`  
- IPv6: `ipv6 route`

---

## Next-Hop Options
A static route’s **next hop** can be defined using:

- **IP address**  
- **Exit interface**  
- **Both IP address and exit interface**

**Types based on next-hop specification:**
- **Next-hop route:** only next-hop IP is specified  
- **Directly connected static route:** only exit interface is specified  
- **Fully specified static route:** both next-hop IP and exit interface are specified

---

## IPv4 Static Route Command
To configure an IPv4 static route:
```
Router(config)# ip route network-address subnet-mask {ip-address | exit-intf | ip-address exit-intf} [distance]
```

> **Note:** You must configure either the **ip-address**, **exit-intf**, or **both**.

---

## IPv6 Static Route Command
To configure an IPv6 static route:
```
Router(config)# ipv6 route ipv6-prefix/prefix-length {ipv6-address | exit-intf [ipv6-address]} [distance]
```

Most parameters are the same as the IPv4 command.

---

## Dual-Stack Topology
A **dual-stack topology** runs both **IPv4** and **IPv6**.  
Initially, no static routes are configured for either protocol.

---

## IPv4 Starting Routing Tables
At the start, routers only have routes for **directly connected networks** and local addresses.

- **R1 → R2:** reachable (direct connection)  
- **R1 → R3 LAN:** unreachable (no static route configured)

---

## IPv6 Starting Routing Tables
Similar to IPv4, routers initially only have routes for **directly connected networks** and local addresses.

- **R1 → R2:** reachable (direct connection)  
- **R1 → R3 LAN:** unreachable (no static route configured)


# 15.2 Configure IP Static Routes

## IPv4 Next-Hop Static Route
- Specifies only the **next-hop IP address**; exit interface is determined automatically.  
- Used when the next hop is known and directly reachable.

**Example:** Three next-hop IPv4 static routes on **R1**:
```
R1(config)# ip route 172.16.1.0 255.255.255.0 172.16.2.2
R1(config)# ip route 192.168.1.0 255.255.255.0 172.16.2.2
R1(config)# ip route 192.168.2.0 255.255.255.0 172.16.2.2
```

---

## IPv6 Next-Hop Static Route
- Specifies only the **next-hop IPv6 address**.  
- Requires enabling **IPv6 unicast routing**.

**Example:** Three IPv6 next-hop static routes on **R1**:
```
R1(config)# ipv6 unicast-routing
R1(config)# ipv6 route 2001:db8:acad:1::/64 2001:db8:acad:2::2
R1(config)# ipv6 route 2001:db8:cafe:1::/64 2001:db8:acad:2::2
R1(config)# ipv6 route 2001:db8:cafe:2::/64 2001:db8:acad:2::2
```

- **R1's routing table** now contains routes to the three remote IPv6 networks.

---

## IPv4 Directly Connected Static Route
- Specifies only the **exit interface** instead of the next-hop IP.  
- Typically used for **point-to-point serial interfaces**.  

**Example:** Three directly connected IPv4 static routes on **R1**:
```
R1(config)# ip route 172.16.1.0 255.255.255.0 s0/1/0
R1(config)# ip route 192.168.1.0 255.255.255.0 s0/1/0
R1(config)# ip route 192.168.2.0 255.255.255.0 s0/1/0
```

> **Note:** Using a **next-hop IP address** is generally recommended.

---

## IPv6 Directly Connected Static Route
- Specifies only the **exit interface**.  
- Used mainly for **point-to-point serial interfaces**.  

**Example:** Three directly connected IPv6 static routes on **R1**:
```
R1(config)# ipv6 route 2001:db8:acad:1::/64 s0/1/0
R1(config)# ipv6 route 2001:db8:cafe:1::/64 s0/1/0
R1(config)# ipv6 route 2001:db8:cafe:2::/64 s0/1/0
```

> **Note:** Using a **next-hop IPv6 address** is generally recommended.

---

## IPv4 Fully Specified Static Route
- Specifies **both exit interface and next-hop IP address**.  
- Needed for **multi-access interfaces** to explicitly identify the next hop.  
- Next-hop IP must be **directly connected** to the exit interface.  
- Recommended for **Ethernet networks**.

---

## IPv6 Fully Specified Static Route
- Specifies **both exit interface and next-hop IPv6 address**.  
- Required when the next-hop address is an **IPv6 link-local address**.  
- Ensures the router knows which interface to use.

**Reason:**  
- Link-local addresses are **not in the IPv6 routing table**.  
- They are **only unique per link**, so the same address may appear on multiple interfaces.  
- Including the **exit interface** avoids ambiguity.

**Example:** IPv6 routing table entry showing both **next-hop link-local address** and **exit interface**.

---

## Verify a Static Route
**Basic commands:**
- `show ip route` / `show ipv6 route`  
- `ping`  
- `traceroute`

**Static route-specific commands:**
- `show ip route static`  
- `show ip route [network]`  
- `show running-config | section ip route`

> **Note:** Replace `ip` with `ipv6` for IPv6 versions.



# 15.3 Configure IP Default Static Routes

## Default Static Route
A **default route** is a static route that **matches all packets** not found in the routing table.  
It serves as the **Gateway of Last Resort**.

**Key points:**
- Represents any network **not in the routing table**  
- Can be **configured locally** or **learned from another router**  
- Commonly used for:
  - **Edge routers** connecting to a service provider  
  - **Stub routers** with only one upstream neighbor  

**Example scenario:** Typical default static route setup.

---

## IPv4 Default Static Route
- Network address: **0.0.0.0**, Subnet mask: **0.0.0.0**  
- Matches **any IPv4 network**  
- Often called a **quad-zero route**

**Command syntax:**
```
Router(config)# ip route 0.0.0.0 0.0.0.0 {ip-address | exit-intf}
```

---

## IPv6 Default Static Route
- Prefix: **::/0**, matches **all IPv6 routes**

**Command syntax:**
```
Router(config)# ipv6 route ::/0 {ipv6-address | exit-intf}
```
---

## Configure a Default Static Route

### IPv4 Example
- Forwards packets **not matching a more specific route** to R2 (172.16.2.2)
```
R1(config)# ip route 0.0.0.0 0.0.0.0 172.16.2.2
```

### IPv6 Example
- Works similarly for IPv6: forwards packets **not matching a more specific route**
```
R1(config)# ipv6 route ::/0 {next-hop-ipv6 | exit-intf}
```

---

## Verify a Default Static Route

### IPv4 Verification
- Command: `show ip route static`  
- An **asterisk (*)** next to `S` indicates it is the **candidate default route**  
- Default route uses **/0 mask** → **matches all packets** not matched by a specific route

### IPv6 Verification
- Command: `show ipv6 route static`  
- Default route uses **::/0 prefix** → **matches all packets** not matched by a specific IPv6 route


# 15.4 Configure Floating Static Routes

## Floating Static Routes
A **floating static route** is a **backup route** used only when the primary route (static or dynamic) fails.

**Key points:**
- Only active if the **primary route fails**  
- Configured with a **higher administrative distance (AD)** than the primary route  
- **AD** indicates route trustworthiness; lower AD is preferred  
- Default static routes have **AD = 1**  
- Increasing AD makes the route **less preferred**, allowing it to "float" until needed

---

## Configure IPv4 and IPv6 Floating Static Routes
- Can be configured for **IPv4** and **IPv6**  
- Use a **higher AD** for the floating route

**IPv4 Example:**
```
R1(config)# ip route 0.0.0.0 0.0.0.0 172.16.2.2 # Primary route
R1(config)# ip route 0.0.0.0 0.0.0.0 10.10.10.2 5 # Floating route (AD = 5)
```
**IPv6 Example:**
```
R1(config)# ipv6 route ::/0 2001:db8:acad:2::2 # Primary route
R1(config)# ipv6 route ::/0 2001:db8:cafe:2::2 5 # Floating route (AD = 5)
```

**Verification:**
- `show ip route` / `show ipv6 route`  
- Floating route **does not appear** while primary route is active

---

## Test the Floating Static Routes
- **Scenario:** R2 fails (both serial interfaces shut down)  
- **Observation on R1:**
  - Syslog messages show links going down  
  - Floating static route becomes **active automatically**  
  - Routing table now uses the **backup route**



# 15.5 Configure Static Host Routes

## Host Routes
A **host route** is a route to a **specific IP address**:  
- **IPv4:** /32 mask  
- **IPv6:** /128 prefix  

**Ways a host route can be added:**
1. **Automatically installed** when an IP address is assigned to an interface  
2. **Manually configured** as a static host route  
3. **Automatically obtained** through other methods (covered later)

---

## Automatically Installed Host Routes
- Cisco IOS installs a **local host route** automatically when an interface has an IP address  
- Improves **handling of packets addressed to the router itself**  
- Added **along with the connected network route** (marked `C`)  
- Local host routes are marked **L** in the routing table

---

## Static Host Routes
- **Manually configured** to direct traffic to a **specific device** (e.g., a server)  
- Uses **/32 for IPv4** or **/128 for IPv6**

**Example:**
- IPv4: 192.168.1.100/32  
- IPv6: 2001:db8:acad:1::100/128

---

## Configure Static Host Routes
**Example on Branch router:**

**IPv4:**
```
Branch(config)# ip route 209.165.200.238 255.255.255.255 198.51.100.2
```

**IPv6:**
```
Branch(config)# ipv6 route 2001:db8:acad::238/128 2001:db8:acad::2
```

---

## Configure IPv6 Static Host Route with Link-Local Next-Hop
- IPv6 next-hop can be a **link-local address** of the adjacent router  
- **Must specify the exit interface** when using a link-local next hop

**Steps:**
1. Remove the original IPv6 static host route  
2. Configure a **fully specified route**:
   - IPv6 address of the destination server  
   - IPv6 link-local address of the ISP router  
   - Exit interface
