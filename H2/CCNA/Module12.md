# 12.1 Introduction to Wireless

## Benefits of Wireless
- WLANs (Wireless Local Area Networks) are used in:
  - Homes
  - Offices
  - Campus environments
- Enable mobility within home and business environments
- Wireless networks adapt to changing needs and technologies

## Types of Wireless Networks

### Wireless Personal-Area Network (WPAN)
- Short-range (20–30 ft / 6–9 m), low power
- IEEE 802.15 standard, 2.4 GHz frequency
- Examples: Bluetooth, Zigbee

### Wireless LAN (WLAN)
- Medium-sized networks, up to ~300 ft
- IEEE 802.11 standard, 2.4 or 5 GHz frequency

### Wireless MAN (WMAN)
- Covers large areas like cities or districts
- Uses licensed frequencies

### Wireless WAN (WWAN)
- Covers national or global areas
- Uses licensed frequencies

## Wireless Technologies

### Bluetooth
- IEEE WPAN standard for device pairing (up to 300 ft / 100 m)
- **Bluetooth Low Energy (BLE):** Supports mesh networks for large-scale devices
- **BR/EDR (Basic Rate / Enhanced Data Rate):** Optimized for point-to-point audio streaming

### WiMAX
- Alternative to broadband wired connections
- IEEE 802.16 standard, range up to 30 miles (50 km)

### Cellular Broadband
- Carries voice and data
- Used in phones, cars, tablets, laptops
- Types:
  - **GSM (Global System for Mobile):** Internationally recognized
  - **CDMA (Code Division Multiple Access):** Mainly used in the US

### Satellite Broadband
- Uses a directional satellite dish aligned with geostationary satellites
- Requires clear line of sight
- Common in rural areas without cable or DSL

## 802.11 Standards
- Defines how radio frequencies are used for WLAN links

| IEEE Standard | Frequency      | Description |
|---------------|---------------|-------------|
| 802.11        | 2.4 GHz       | Data rates up to 2 Mb/s |
| 802.11a       | 5 GHz         | Data rates up to 54 Mb/s |
| 802.11b       | 2.4 GHz       | Data rates up to 11 Mb/s; longer range than 802.11a; better penetration of buildings |
| 802.11g       | 2.4 GHz       | Data rates up to 54 Mb/s; backward compatible with 802.11b |
| 802.11n       | 2.4 & 5 GHz   | Data rates 150–600 Mb/s; uses MIMO (multiple antennas) |
| 802.11ac      | 5 GHz         | Data rates 450 Mb/s – 1.3 Gb/s; supports up to 8 antennas |
| 802.11ax      | 2.4 & 5 GHz   | High-Efficiency Wireless (HEW); supports 1–7 GHz frequencies |

## Radio Frequencies
- WLAN devices operate within the electromagnetic spectrum
- Main WLAN bands:
  - **2.4 GHz**
  - **5 GHz (SHE)**

## Wireless Standards Organizations
- Ensure devices from different manufacturers work together

### International Telecommunication Union (ITU)
- Regulates radio spectrum and satellite orbits

### Institute of Electrical and Electronics Engineers (IEEE)
- Defines radio frequency modulation
- Maintains LAN/MAN standards with IEEE 802 family

### Wi-Fi Alliance
- Promotes WLAN growth and adoption
- Ensures interoperability of 802.11-based products

# 12.2 WLAN Components

## Wireless NICs
- Devices like laptops, tablets, smartphones, and some automobiles have **integrated wireless NICs** (Network Interface Cards) with a radio transmitter/receiver.
- If a device lacks an integrated NIC, a **USB wireless adapter** can be used.

## Wireless Home Router
- Home users connect wireless devices using a **wireless router**.
- Roles of a wireless router:
  - **Access Point:** Provides wireless access
  - **Switch:** Connects wired devices
  - **Router:** Provides a default gateway to other networks and the Internet

## Wireless Access Point (AP)
- Wireless clients use their **NIC** to discover nearby APs.
- Clients **associate** and **authenticate** with an AP.
- Once authenticated, users can access network resources.

## AP Categories
- APs can be **autonomous** or **controller-based**.

### Autonomous APs
- Standalone devices configured via **CLI** or **GUI**
- Operate independently
- Managed manually by an administrator

### Controller-Based APs (Lightweight APs / LAPs)
- Communicate with a **WLAN Controller (WLC)** using **LWAPP**
- Automatically configured and managed by the WLC

## Wireless Antennas
- **Types of external antennas:**

### Omnidirectional
- Provides 360° coverage
- Ideal for homes and office areas

### Directional
- Focuses the radio signal in a specific direction
- Examples: Yagi, parabolic dish

### Multiple Input Multiple Output (MIMO)
- Uses multiple antennas (up to 8) to increase bandwidth

# 12.3 WLAN Operation

## 802.11 Wireless Topology Modes
- **Ad hoc mode:**  
  - Connects clients in a peer-to-peer manner without an AP
- **Infrastructure mode:**  
  - Connects clients to the network using an AP
- **Tethering:**  
  - Variation of ad hoc mode  
  - A smartphone or tablet with cellular data creates a personal hotspot

## BSS and ESS
- **Infrastructure mode** defines two topology blocks:

### Basic Service Set (BSS)
- Uses a single AP to connect all associated wireless clients
- Clients in different BSSs **cannot communicate** directly

### Extended Service Set (ESS)
- Union of two or more BSSs connected via a wired distribution system
- Clients in each BSS **can communicate** through the ESS

## CSMA/CA
- WLANs are **half-duplex**; a client cannot "hear" while sending, so collisions are possible
- WLANs use **Carrier Sense Multiple Access with Collision Avoidance (CSMA/CA)** to manage transmissions

**Client transmission process:**
1. **Listen** to the channel to check if it is idle  
2. **Send RTS (Ready to Send)** message to the AP  
3. **Receive CTS (Clear to Send)** message from the AP  
4. If no CTS is received, **wait a random time** and retry  
5. **Transmit the data** once access is granted  
6. **Acknowledge transmissions**; if no acknowledgment is received, assume a collision and restart

## Wireless Client and AP Association
- Wireless devices must **associate with an AP or wireless router** to communicate  
- **Three-stage process:**
1. **Discover** a wireless AP  
2. **Authenticate** with the AP  
3. **Associate** with the AP

### Association Parameters
- For successful association, a client and AP must agree on:
  1. **SSID:** Network name  
  2. **Password:** Required for authentication  
  3. **Network Mode:** 802.11 standard in use  
  4. **Security Mode:** WEP, WPA, or WPA2  
  5. **Channel Settings:** Frequency bands in use

## Passive and Active Discover Mode
- Wireless clients connect to an AP using **passive** or **active scanning**

### Passive Mode
- AP **advertises its service** by sending **beacon frames** periodically  
- Beacons include:
  - SSID
  - Supported standards
  - Security settings

### Active Mode
- Clients **must know the SSID**  
- Client **broadcasts a probe request** on multiple channels to discover the AP

# 12.4 CAPWAP Operation

## Introduction to CAPWAP
- **CAPWAP** is an IEEE standard protocol that allows a **WLAN Controller (WLC)** to manage multiple APs and WLANs.
- Based on **LWAPP**, but adds **Datagram Transport Layer Security (DTLS)** for additional security.
- **Encapsulates and forwards** WLAN client traffic between an AP and WLC over tunnels using **UDP ports 5246 and 5247**.
- Operates over **IPv4** and **IPv6**:
  - IPv4 uses **IP protocol 17**
  - IPv6 uses **IP protocol 136**

## Split MAC Architecture
- CAPWAP **Split MAC** divides AP functions between the **AP** and the **WLC**.

| AP MAC Functions                          | WLC MAC Functions                                |
|------------------------------------------|-------------------------------------------------|
| Beacons and probe acknowledgements       | Authentication                                  |
| Retransmissions                           | Association and re-association of roaming clients |
| Frame queueing and packet prioritization | Frame translation to other protocols           |
| MAC layer data encryption                 | Termination of 802.11 traffic on a wired interface |

## DTLS Encryption
- **DTLS** secures communication between the AP and the WLC.
- **Enabled by default** to protect the CAPWAP **control channel** and encrypt all **management/control traffic**.
- **Data encryption** is **disabled by default**:
  - Requires a **DTLS license** on the WLC  
  - Must be enabled on the AP after licensing

## FlexConnect APs
- **FlexConnect** allows AP configuration and control over a WAN link.
- Two operation modes:

| Mode             | Description                                                                                       |
|-----------------|---------------------------------------------------------------------------------------------------|
| **Connected**    | WLC is reachable. FlexConnect AP has CAPWAP connectivity; WLC performs all CAPWAP functions.      |
| **Standalone**   | WLC is unreachable. AP handles some WLC functions locally, such as switching client traffic and performing client authentication. |




# 12.5 Channel Management

## Frequency Channel Saturation
- High demand on a wireless channel can cause **oversaturation**, reducing communication quality.
- Techniques to use channels more efficiently:

### Direct-Sequence Spread Spectrum (DSSS)
- Spreads a signal over a larger frequency band
- Used by **802.11b** to avoid interference on 2.4 GHz

### Frequency-Hopping Spread Spectrum (FHSS)
- Rapidly switches the carrier among many frequency channels
- Sender and receiver must be synchronized
- Used by the **original 802.11 standard**

### Orthogonal Frequency-Division Multiplexing (OFDM)
- Divides a single channel into multiple sub-channels on adjacent frequencies
- Reduces interference and increases efficiency
- Used by **802.11a/g/n/ac**

## Channel Selection

### 2.4 GHz Band
- Multiple channels, each **22 MHz wide**, separated by **5 MHz**
- Best practice for multiple APs: use **non-overlapping channels** such as **1, 6, 11**

### 5 GHz Band
- 24 channels, each separated by **20 MHz**
- **Non-overlapping channels:** 36, 48, 60

## Plan a WLAN Deployment
- User support depends on:
  - **Facility layout**
  - **Number of people and devices**
  - **Expected data rates**
  - **Use of non-overlapping channels** and **AP transmit power settings**
- Consider **circular coverage area** when placing APs


# 12.6 WLAN Threats

## Wireless Security Overview
- WLANs are **open to anyone within range** of an AP with proper credentials.
- Attacks can come from:
  - **Outsiders**
  - **Disgruntled employees**
  - **Unintentional employee actions**
- Common threats include:
  - **Interception of data**
  - **Wireless intruders**
  - **Denial of Service (DoS) attacks**
  - **Rogue APs**

## DoS Attacks
- Wireless **Denial of Service (DoS) attacks** can result from:
  - **Improperly configured devices**
  - **Malicious users** interfering intentionally
  - **Accidental interference**
- **Mitigation strategies:**
  - Harden all devices  
  - Keep passwords secure  
  - Create backups  
  - Apply configuration changes during off-hours

## Rogue Access Points
- A **rogue AP** is an AP or router connected **without authorization**, violating corporate policy.
- Threats from rogue APs:
  - Capture **MAC addresses**  
  - Capture **data packets**  
  - Gain access to **network resources**  
  - Launch **man-in-the-middle attacks**
- Personal hotspots can also act as rogue APs.
- **Prevention strategies:**
  - Configure **WLCs** with rogue AP policies  
  - Use **monitoring software** to detect unauthorized APs

## Man-in-the-Middle (MITM) Attack
- In a **MITM attack**, the attacker sits **between two legitimate entities** to read or modify data.
- Common example: **"evil twin AP"**
  - Rogue AP uses the **same SSID** as a legitimate AP
- **Defense strategies:**
  - Identify all **legitimate devices** on the WLAN  
  - Ensure all users are **authenticated**  
  - Monitor for **abnormal devices or traffic**

# 12.7 Secure WLANs

## SSID Cloaking and MAC Address Filtering
- Early security features to protect WLANs:

### SSID Cloaking
- APs or routers can **disable the SSID beacon frame**
- Clients must **manually configure** the SSID to connect

### MAC Address Filtering
- Administrators can **allow or deny clients** based on their **MAC address**
- Only permitted devices can join the WLAN

## 802.11 Original Authentication Methods
- WLAN security uses **authentication** and **encryption**
- Two original 802.11 methods:

### Open System Authentication
- **No password** required  
- Used for **public Wi-Fi** (cafes, airports, hotels)  
- Security responsibility falls on the **client** (e.g., VPN)

### Shared Key Authentication
- Uses **WEP, WPA, WPA2, WPA3** to authenticate and encrypt data  
- Requires a **pre-shared password** between client and AP

## Shared Key Authentication Methods
| Authentication Method | Description |
|-----------------------|-------------|
| **WEP** | Original 802.11 security using **RC4 encryption** with static key. **Not recommended**. |
| **WPA** | Uses **TKIP** to encrypt Layer 2 payload; supports legacy WLAN devices. |
| **WPA2** | Uses **AES** encryption; considered the **strongest widely used encryption**. |
| **WPA3** | Next-gen security; uses latest methods, disallows outdated protocols, requires **PMF**. |

## Authenticating a Home User
- Routers typically support **WPA** and **WPA2**, with WPA2 having two modes:

### Personal
- For **home/small office networks**  
- Authenticate using a **pre-shared key (PSK)**  
- No special server required

### Enterprise
- For **enterprise networks**  
- Requires a **RADIUS server**  
- Devices authenticated by **RADIUS**  
- Users authenticate via **802.1X/EAP**

## Encryption Methods
- WPA and WPA2 use:

### TKIP
- Used by **WPA**  
- Encrypts Layer 2 payload  
- Supports **legacy WLAN devices**

### AES
- Used by **WPA2**  
- Uses **CCMP** to ensure encrypted or unencrypted data integrity

## Authentication in the Enterprise
- Enterprise WLANs require a **RADIUS server** for **AAA**:

1. **RADIUS Server IP Address** – IP of the server  
2. **UDP Port Numbers** –  
   - 1812 for Authentication, 1813 for Accounting  
   - Can also use 1645/1646  
3. **Shared Key** – Authenticates **AP with RADIUS server**

- **Note:** 802.1X handles user authentication and authorization centrally

## WPA3
- Recommended over WPA2 for stronger security

### WPA3 — Personal
- Protects against **brute force attacks**  
- Uses **SAE** (Simultaneous Authentication of Equals)

### WPA3 — Enterprise
- Uses **802.1X/EAP**  
- Requires **192-bit cryptography**  
- Prevents mixing older security protocols

### Open Networks
- No authentication required  
- Uses **OWE** to encrypt wireless traffic

### IoT Onboarding
- Uses **DPP** to quickly onboard IoT devices
