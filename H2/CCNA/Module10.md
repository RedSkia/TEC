# 10.1 Endpoint Security

## Network Attacks Today

Modern enterprise networks face many types of attacks.

### 1. Distributed Denial of Service (DDoS)
* **Description:** A **coordinated attack** using many compromised devices (called **zombies**).
* **Goal:** To **overwhelm** a website or service with traffic.
* **Effect:** The service slows down or completely **shuts down** public access.

### 2. Data Breach
* **Description:** Attackers **break into servers or hosts** to steal sensitive information.
* **Risk:** Exposure of confidential data (customer records, passwords, financial details).

### 3. Malware (Malicious Software)
* **Description:** **Malicious software** that infects systems and causes harm.
* **Example (Ransomware):** Encrypts files (like **WannaCry**) and locks access until a ransom is paid.
* **Other Risks:** Stealing data, spying on users, or damaging system files.

---

## Network Security Devices

These devices protect the network perimeter from unauthorized access.

### 1. Virtual Private Network (VPN) Enabled Router
* **Function:** Creates a **secure, encrypted connection** for remote users over public networks.
* **Benefit:** Allows safe access to the enterprise network. (VPN services can often be built into a firewall.)

### 2. Next-Generation Firewall (NGFW)
* **Function:** Provides **advanced protection** beyond traditional firewalls.
* **Key Features:**
    * **Stateful packet inspection:** Monitors the state of active connections.
    * **Application visibility and control:** Manages access based on the application, not just the port.
    * **Next-Generation Intrusion Prevention System (NGIPS):** Proactively blocks threats.
    * **Advanced Malware Protection (AMP):** Fights sophisticated malware.
    * **URL filtering:** Secures web traffic by blocking dangerous links.

### 3. Network Access Control (NAC)
* **Function:** Manages **who** can access the network and **what** they can do.
* **Uses the AAA Model:**
    * **Authentication:** Verifies user identity (Who are you?).
    * **Authorization:** Defines what users are allowed to access (What can you do?).
    * **Accounting:** Tracks user activities (What did you do?).
* **Enterprise Example:** **Cisco Identity Services Engine (ISE)**.

---

## Endpoint Protection (![](./_/M10_Endpoint.png))

### What Are Endpoints?
* **Definition:** Devices that **connect to the network**.
* **Examples:** Laptops, desktops, servers, IP phones, and employee-owned (**BYOD**) devices.
* **Risk:** They are **common targets** for attacks, especially via email or web browsing.

### Traditional Endpoint Security
These tools run directly on the device (host-based):
* **Antivirus/Antimalware:** Detects and removes malicious software.
* **Host-Based Firewall:** Filters traffic going to and from the endpoint.
* **Host-Based Intrusion Prevention System (HIPS):** Blocks suspicious activities on the device.

### Modern Endpoint Protection
This is a layered security approach using multiple tools:
* **Network Access Control (NAC):** Controls which devices are allowed to connect.
* **Advanced Malware Protection (AMP):** Detects and responds to malware threats in real-time.
* **Email Security Appliance (ESA):** Blocks phishing and email-based attacks.
* **Web Security Appliance (WSA):** Protects against malicious websites and downloads.

---

## Cisco Email Security Appliance (ESA)

### Overview
* **Role:** Monitors **Simple Mail Transfer Protocol (SMTP)** traffic to protect email.
* **Intelligence:** Receives **real-time threat intelligence** updates (every 3–5 minutes) from **Cisco Talos**.

### Key Functions
* **Block Known Threats:** Stops malicious emails before they reach users.
* **Remediate Stealth Malware:** Finds and fixes malware that bypassed initial checks.
* **Discard Emails:** Removes emails containing malicious or suspicious links.
* **Block Access:** Prevents users from accessing newly infected or dangerous websites.
* **Encrypt Outgoing Emails:** Ensures confidentiality and prevents data leaks.

---

## Cisco Web Security Appliance (WSA)

### Overview
* **Role:** Protects against **web-based threats** and controls user web traffic.
* **Integrates** multiple security features for comprehensive protection.

### Key Features
* **Advanced Malware Protection (AMP):** Detects and blocks malicious software.
* **Application Visibility and Control:** Monitors and manages web applications in use.
* **Acceptable Use Policy Controls:** Enforces company rules for web access.
* **Detailed Reporting:** Provides insights into user web activity and threat events.

### Web Access Management
* Gives administrators **complete control** over user internet access.
* Specific activities (e.g., chat, messaging, video, audio) can be:
    * **Allowed**
    * **Restricted** (by time or bandwidth)
    * **Completely Blocked**

### Security Functions
* **Blacklist and URL Filtering:** Blocks access to unsafe or inappropriate websites.
* **Malware Scanning:** Detects malicious content within web traffic.
* **URL Categorization:** Sorts websites by type or risk level.
* **Web Application Filtering:** Controls access to specific web-based applications.
* **Encryption/Decryption of Web Traffic:** Inspects secure **HTTPS** traffic safely while maintaining privacy.

# 10.2 Access Control

---

## Authentication with a Local Password

### Overview
* **Authentication** verifies a user's identity to grant access.
* The **simplest method** is using a **local username and password** configured directly on a device's **console**, **VTY**, or **AUX** lines.

### SSH (Secure Shell)
* **SSH** is the **secure replacement for Telnet**.
* It provides **encrypted remote access** and requires a **username and password**.
* Credentials are **verified locally** against the device's internal user database.

### Limitations of Local Authentication
* **Not scalable:** User accounts must be **manually configured** on *every* device.
* **No central management:** No easy way to manage hundreds of users or devices.
* **No fallback:** If the local database fails, nobody can log in.
* **Best for:** **Small networks** or lab environments.

---

## AAA Components (The Access Control Framework)

### Overview
* **AAA** stands for **Authentication, Authorization, and Accounting**.
* It is the core framework for **secure, controlled, and traceable access** to network devices and resources.

### Components of AAA
1.  **Authentication (Who are you?)**
    * Verifies **who** the user is before access is granted.
    * *Example:* Checking a username and password.

2.  **Authorization (What can you do?)**
    * Determines **what** the authenticated user is allowed to access or perform.
    * *Example:* Granting access to specific configuration commands or network areas.

3.  **Accounting (What did you do?)**
    * Tracks and **records user activities** on the network.
    * *Example:* Logging session times, executed commands, or data usage for audit purposes.

---

## Authentication Methods

### Overview
AAA Authentication can use two main methods: **Local** or **Server-Based**.

### 1. Local AAA Authentication
* **How it works:** Usernames and passwords are **stored locally** on the network device (e.g., the router or switch).
* **Benefit:** Simple and quick to configure.
* **Best for:** **Small networks** with few users or devices.

### 2. Server-Based AAA Authentication
* **How it works:** Devices connect to a **central AAA server** (like Cisco ISE) for all authentication.
* **Server Protocols:** The device communicates with the server using **RADIUS** or **TACACS+**.
* **Benefit:** **Centralized management** and **greater scalability** for large enterprises.

---

## Authorization

### Overview
* **Authorization** happens automatically **after** a user is successfully authenticated.
* The user **does not perform any extra steps** for this process.

### How It Works
* The **AAA server** evaluates attributes (privileges and restrictions) associated with the user's identity.
* It then determines the **exact commands and resources** the user is permitted to use.
* **Goal:** Ensures users **only access functions** they are specifically allowed to use.

---

## Accounting

### Overview
* **Accounting** tracks and reports all user activity on the network.
* **Purpose:** Provides data for **auditing, troubleshooting, and billing** (if needed).

### Data Collected
* **Connection Times:** Start and stop times of user sessions.
* **Commands Executed:** Logs every configuration or EXEC command used.
* **Traffic Info:** Records the number of packets and bytes transmitted.
* **User Details:** Timestamped logs of who did what.
* **Goal:** Provides **accountability** and evidence for security investigations.

---

## 802.1X (Port-Based Access Control) (![](./_/M10_802.png))

### Overview
* **IEEE 802.1X** is a **port-based access control protocol**.
* **Function:** Restricts **unauthorized devices** from connecting to a LAN via public switch ports or wireless access points until they are authenticated.

### Roles in 802.1X

1.  **Client (Supplicant)**
    * The end device (wired or wireless) requesting network access.
    * Runs the 802.1X client software.

2.  **Switch (Authenticator)**
    * Acts as a **middleman** between the client and the server.
    * Requests the client's identifying information.
    * Forwards the information to the server and relays the server's access decision back to the client. (A wireless access point can also be the authenticator).

3.  **Authentication Server**
    * The central server that **validates the client's identity**.
    * Notifies the Switch/Access Point whether the client is **Authorized** or **Denied** access to the network services.

# 10.3 Layer 2 Security Threats

---

## Layer 2 Vulnerabilities (![](./_/M10_OSI.png))

### Overview
* The **OSI model** has seven layers. Security solutions like **VPNs, firewalls, and IPS** typically protect the **upper layers (3 through 7)**.
* **Layer 2 (Data Link Layer)** is often overlooked but is a critical point of failure.

### Why Layer 2 Security Matters
* If **Layer 2 is compromised**, all higher layers (3–7) become vulnerable.
* **Example:** An attacker gaining access to the internal network can **capture all Layer 2 frames**, making high-layer encryption (like VPNs) ineffective.
* Attackers can cause significant damage to the **LAN infrastructure** by exploiting Layer 2.

---

## Switch Attack Categories

### Overview
* **Layer 2 is considered the weakest link** because traditional LANs were built on **trusting all connected devices**.
* Modern attacks target **switches and LAN infrastructure** directly.
* **Internal threats** are a major concern at this layer.

### Attack Categories and Examples

| Category | Description of Attack Type |
| :--- | :--- |
| **MAC Table Attacks** | Overloading the switch's MAC address table (**MAC address flooding**). |
| **VLAN Attacks** | Bypassing VLAN isolation (**VLAN hopping** or **VLAN double-tagging**). |
| **DHCP Attacks** | Overloading the DHCP server (**DHCP starvation**) or faking a DHCP server (**DHCP spoofing**). |
| **ARP Attacks** | Faking MAC-to-IP relationships (**ARP spoofing** or **ARP poisoning**). |
| **Address Spoofing** | Using a fake MAC address or IP address to hide identity. |
| **STP Attacks** | Manipulating the Spanning Tree Protocol (STP) to redirect traffic. |

---

## Switch Attack Mitigation Techniques

### Key Layer 2 Security Solutions
These solutions run on the switch to protect against the specific threats listed above:

| Solution | Threat Protection |
| :--- | :--- |
| **Port Security** | Prevents the switch's MAC table from being flooded. Also helps prevent DHCP starvation. |
| **DHCP Snooping** | **Blocks** fake (spoofed) DHCP servers and prevents resource-draining DHCP starvation attacks. |
| **Dynamic ARP Inspection (DAI)** | **Blocks** fake ARP messages, preventing ARP spoofing and poisoning. |
| **IP Source Guard (IPSG)** | **Blocks** unauthorized MAC and IP addresses, preventing address spoofing attacks. |

### Additional Security Recommendations
These practices secure the management access to the switches themselves:

* **Secure Management Protocols:** Use **SSH, SCP, SFTP, and SSL/TLS** instead of insecure protocols (like Telnet).
* **Out-of-Band Management (OOB):** Use a **separate network** for device management to isolate it from user traffic.
* **Dedicated Management VLAN:** Isolate management traffic by placing it on its own **VLAN**.
* **Access Control Lists (ACLs):** Filter unwanted or unauthorized management access to the network devices.


## MAC Address Table Attack

### Switch Operation Review
- **Layer 2 LAN switches** forward frames using a **MAC address table**.  
- The table is built from the **source MAC addresses** in received frames.  
- MAC address tables are **stored in memory** to enable **efficient frame switching**.

# 10.4 MAC Address Table Attack

---

## MAC Address Table Flooding (![](./_/M10_MACFlooding.png))

### Overview
* Switches use the **source MAC addresses** of incoming frames to build a **MAC address table**.
* This MAC table has a **fixed size** due to limited memory.

### The Attack (How it Works)
* An attacker sends a massive flood of frames, each with a **fake (spoofed) source MAC address**.
* This flood quickly **fills the MAC table** with invalid entries until the table is full.

### Result
* Once the table is full, the switch can no longer learn legitimate MAC addresses.
* The switch then defaults to treating all unknown unicast frames as if their destination is unknown.
* This forces the switch to **flood** those frames out **all ports on the same VLAN**.
* The attacker can now **capture (eavesdrop on) all traffic** flowing through that local LAN/VLAN.

### Scope & Danger
* **Scope:** The attack and traffic capture are limited to the **local LAN or VLAN** where the attacker is connected.
* **Danger:** It bypasses normal switching isolation, allowing **eavesdropping** and degrading switch performance.

---

## MAC Address Table Attack Mitigation

### Why Mitigation is Crucial
* Tools like **macof** can quickly send **thousands of bogus frames per second**.
* Even high-end switches can be **overflowed in seconds** (e.g., a 132,000-entry table).
* An overflowed switch port will **flood traffic out all connected ports**, potentially affecting **other Layer 2 switches**.

### Mitigation Solution: Port Security
* **Implement Port Security** on all access switch ports.
* **Port Security** limits the **number of learned source MAC addresses** allowed on a single port.
* **Benefit:** It prevents the MAC address table from overflowing by strictly **controlling which devices can connect** and how many MACs are learned per port.

# 10.5 LAN Attacks

---

## VLAN Hopping Attacks (![](./_/M10_VlanHop.png))

### Overview
* **VLAN hopping** allows an attacker on one VLAN to **access traffic on other VLANs** without a router.
* This bypasses VLAN isolation, allowing traffic viewing or manipulation across VLANs.

### How it Works (Basic Method)
1.  Attacker's host spoofs itself as a switch by sending **DTP (Dynamic Trunking Protocol)** signals.
2.  If successful (e.g., if the port is set to 'dynamic desirable'), the switch establishes a **trunk link** with the attacker's host.
3.  The attacker can now **send and receive traffic on any VLAN** configured on that trunk.

---

## VLAN Double-Tagging Attacks

### Overview
* This attack allows an attacker to send a frame to a **target VLAN** that is different from the frame's initial VLAN tag.
* The attack uses a frame with **two VLAN tags**.

### Steps of the Attack
1.  **Attacker Sends Frame:** The attacker sends a frame with:
    * **Outer Tag:** Matches the **native VLAN** of the trunk port.
    * **Inner Tag:** Is the **target VLAN** the attacker wants to reach.
2.  **First Switch Processing:**
    * The switch sees the **outer tag** matches its native VLAN.
    * It **strips the outer tag** and forwards the frame as untagged traffic on the native VLAN.
    * The **inner tag** remains intact and is ignored by the first switch.
3.  **Second Switch Processing (Target Switch):**
    * The second switch receives the frame, which still has the attacker's inner tag.
    * The switch reads the **inner tag** and forwards the frame to the **target VLAN**.

### Key Points & Mitigation
* **Unidirectional:** The attack only works if the attacker is on the **same VLAN as the native VLAN** of a trunk port.
* **Mitigation (Prevention):**
    1.  **Disable trunking** on all access ports.
    2.  **Manually enable** trunking (do not use auto-trunking/DTP).
    3.  **Change the native VLAN** used for trunks to an unused VLAN ID.

---

## DHCP Attacks

### Overview
* **DHCP (Dynamic Host Configuration Protocol)** servers assign crucial network settings to clients, including: IP address, subnet mask, default gateway, and DNS servers.

### DHCP Message Exchange (![](./_/M10_DCHP.png))
Clients and servers use a four-step process:
1.  **DHCP Discover:** Client broadcasts to find servers.
2.  **DHCP Offer:** Server offers an IP address.
3.  **DHCP Request:** Client requests the offered IP.
4.  **DHCP Acknowledge (ACK):** Server confirms and assigns the configuration.

### Types of DHCP Attacks

| Attack Type | Goal | Method |
| :--- | :--- | :--- |
| **DHCP Starvation** | Cause a **Denial of Service (DoS)** for legitimate clients. | Attacker uses a tool (like Gobbler) to flood the server with requests using **bogus MAC addresses**, leasing the entire pool of available IPs. |
| **DHCP Spoofing** | Provide clients with **false IP configuration**. | A rogue DHCP server connects to the network and assigns bad information (e.g., its own IP as the **Default Gateway** for a Man-in-the-Middle attack, or a malicious **DNS Server**). |

* **Mitigation:** Implement **DHCP Snooping** on switches.

---

## ARP Attacks

### Overview
* **ARP (Address Resolution Protocol)** maps an **IP address to a MAC address**.
* A host broadcasts an ARP Request, and the host with the matching IP responds with its MAC in an ARP Reply.
* **Gratuitous ARP:** An unsolicited ARP Reply used to update ARP tables without a request.

### ARP Spoofing / ARP Poisoning
* **Method:** Attacker sends a **gratuitous ARP** with a fake MAC address to a switch or multiple hosts.
* **Result:** Hosts or the switch update their ARP/MAC tables with the fake information.
* **Common Goal:** Attacker maps their own MAC address to the **Default Gateway's IP address** to enable a **Man-in-the-Middle (MITM)** attack.

* **IPv6 Note:** Uses ICMPv6 **Neighbor Discovery Protocol** for resolution, which has built-in spoofing protection.
* **Mitigation:** Implement **Dynamic ARP Inspection (DAI)** on switches.

---

## Address Spoofing Attacks

### IP Address Spoofing
* Attacker hijacks a valid IP or uses a random IP on the subnet.
* Difficult to mitigate, especially within the local subnet.

### MAC Address Spoofing
* Attacker changes their device's MAC address to match a **target host**.
* The switch updates its MAC table, forwarding the target's traffic to the attacker.
* Since Layer 2 has no built-in verification, the attacker can continuously send frames to maintain the fake MAC-to-port mapping.

* **Mitigation:** Implement **IP Source Guard (IPSG)** to protect against both IP and MAC spoofing.

---

## STP Attack

### Overview
* Attackers manipulate the **Spanning Tree Protocol (STP)** to change the network topology.
* **Goal:** Force all traffic to pass through the attacker's machine to capture it.

### How it Works
* Attacker broadcasts **STP Bridge Protocol Data Units (BPDUs)**.
* The BPDUs contain a fake, very low **Bridge Priority**, tricking the network into electing the attacker's machine as the new **Root Bridge**.
* This forces the switched domain to recalculate the spanning tree, redirecting traffic toward the attacker.

* **Mitigation:** Enable **BPDU Guard** on all user-facing access ports.

---

## CDP Reconnaissance

### What is CDP?
* **Cisco Discovery Protocol (CDP)** is a proprietary Layer 2 protocol enabled by default on Cisco devices.
* Used by administrators for device discovery and troubleshooting.

### The Risk
* CDP sends periodic, **unencrypted, unauthenticated** broadcasts.
* These broadcasts contain sensitive device information: **IP address, IOS version, platform, capabilities, and native VLAN.**
* Attackers on the same Layer 2 segment can easily gather this data for **reconnaissance** before launching a targeted attack.

### Mitigation (Prevention)
* **Limit or disable CDP** on all ports that connect to untrusted devices (edge ports).
* **Disable CDP Globally:**
    ```
    no cdp run
    ```
* **Disable CDP on an Interface:**
    ```
    interface <type/number>
      no cdp enable
    ```
* **LLDP Note:** Link Layer Discovery Protocol (LLDP) is the vendor-neutral alternative, and it carries the same reconnaissance risks.