# 7.1 DHCPv4 Concepts

## DHCPv4 Server and Client

* **Dynamic Host Configuration Protocol v4 (DHCPv4)** automatically assigns **IPv4 addresses** and other network configuration info to devices.
* Commonly used for **desktop clients** as they form the majority of network nodes.
* **Benefit:** Saves time and reduces errors compared to manual (static) IP configuration.

---

## DHCPv4 Server Options

* **Dedicated DHCPv4 Server:** More **scalable** and easier to manage in larger networks.
* **Cisco Router as DHCPv4 Server:** Useful in **Small Office/Home Office (SOHO)** or branch networks; Cisco IOS supports a full-featured DHCPv4 server.

---

## DHCPv4 Lease Process (Client/Server Model)

* **Leasing:** The DHCPv4 server **leases an IPv4 address** from an address pool for a limited time (e.g., 24 hours to a week or more).
* **Renewal:** The client must **periodically contact the server** to renew/extend the lease.
* **Expiration:** If the lease **expires**, the DHCP server **reclaims the address** and returns it to the available pool.
* **Efficiency:** The lease system keeps IP address usage **efficient** by preventing permanently held or wasted addresses.

---

## Steps to Obtain a DHCPv4 Lease (DORA) (![](./_/M7_ObtainLease.png))

When a client boots, it follows the four-step **DORA** process:

| Step | Message | Action | Purpose |
| :---: | :--- | :--- | :--- |
| **1** | **D**iscover (`DHCPDISCOVER`) | Client **broadcasts** a message. | Locate available DHCPv4 servers. |
| **2** | **O**ffer (`DHCPOFFER`) | Server replies with an **offer** (suggested IP, mask, gateway, DNS, etc.). | Inform the client of available configuration. |
| **3** | **R**equest (`DHCPREQUEST`) | Client **broadcasts** a request to accept the offered IP and configuration. | Formally ask for the offered IP. |
| **4** | **A**cknowledgment (`DHCPACK`) | Server confirms with an **acknowledgment**. | Grant the lease; client now has a valid IP configuration. |

---

## Steps to Renew a DHCPv4 Lease (![](./_/M7_RenewLease.png))

Before a lease expires, the client attempts to renew it:

1.  **DHCP Request (`DHCPREQUEST`):** Client sends the request **directly** (unicast) to the original DHCP server.
2.  **Backup Request:** If no `DHCPACK` is received, the client **broadcasts** a `DHCPREQUEST` to allow other servers to respond.
3.  **DHCP Acknowledgment (`DHCPACK`):** Server responds, confirming the **lease renewal** and allowing the client to continue using the IP address.

***

# 7.2 Configure a Cisco IOS DHCPv4 Server (![](./_/M7_DHCPv4Server.png))

A **Cisco IOS router** can be configured as a DHCPv4 server to assign IPv4 addresses dynamically from managed **address pools**.

## Steps to Configure a Cisco IOS DHCPv4 Server

| Step | Command Syntax | Mode | Description |
| :---: | :--- | :--- | :--- |
| **1** | `ip dhcp excluded-address <low-address> [high-address]` | Global Config | **Excludes reserved addresses** (e.g., for routers, servers, printers) from the pool. |
| **2** | `ip dhcp pool POOL-NAME` | Global Config | **Defines a DHCP pool** and enters DHCP configuration mode. |
| **3** | `network network-number mask` | DHCP Config | Defines the **range of available addresses** for the pool. |
| **4** | `default-router address` | DHCP Config | Specifies the client's **default gateway**. |
| **5** | `dns-server address` (Optional) | DHCP Config | Provides the **DNS server** IP address(es). |
| **6** | `domain-name domain` (Optional) | DHCP Config | Specifies the network **domain name**. |

---

## DHCPv4 Pool Configuration Commands

| Task | Command Syntax |
| :--- | :--- |
| Define the address pool | `network network-number [mask | /prefix-length]` |
| Define the default gateway | `default-router address [address2 ...]` |
| Define a DNS server | `dns-server address [address2 ...]` |
| Define the domain name | `domain-name domain` |
| Define the duration of the lease | `lease {days [hours [minutes]]}` |

---

## DHCPv4 Verification and Management

| Command | Purpose |
| :--- | :--- |
| `show running-config | section dhcp` | Displays the configured DHCPv4 pool(s) and excluded addresses. |
| `show ip dhcp binding` | Shows a list of **assigned IPv4 addresses** (bindings) to MAC addresses. |
| `show ip dhcp server statistics` | Displays the count of DHCPv4 messages (Discover, Offer, Request, ACK) sent and received. |
| `no service dhcp` | **Disables** the global DHCPv4 server process (use `service dhcp` to re-enable). |

---

## DHCPv4 Relay Agent (![](./_/M7_relay.png))

A router is configured as a **DHCPv4 relay agent** when the DHCPv4 server is on a **different subnet** than the clients (since routers don't forward broadcast messages).

* **Solution:** Use the `ip helper-address` command.
* **Command:** `ip helper-address <server-address>`
* **Mode:** Interface configuration mode (on the interface facing the clients).
* **Action:** The router accepts client **broadcast requests** and forwards them as **unicast messages** to the DHCPv4 server.
* **Note:** The `ip helper-address` command also forwards seven other UDP services by default (including DNS, TFTP, and NetBIOS).

***

# 7.3 Configure a DHCPv4 Client

## Cisco Router as a DHCPv4 Client (![](./_/M7_RouterClient.png))

A Cisco router can be configured to obtain an IP address from an external DHCP server (like an ISP) for its WAN interface, commonly used in **SOHO** environments.

* **Configuration Command:**
    ```cli
    R1(config-if)# ip address dhcp
    ```
* **Action:** The router interface acts as a DHCPv4 client, requesting an IPv4 address, mask, and other configuration details from the server.
* **Verification:** Use the `show ip interface [interface-id]` command to confirm the allocated IP address and status.

---

## Home Router as a DHCPv4 Client

* Home routers are usually preconfigured to act as a DHCPv4 client on their **WAN port**.
* The default Internet connection type is typically set to **Automatic Configuration - DHCP** to quickly connect to the ISP's cable or DSL modem.