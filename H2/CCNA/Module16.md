# 16.1 Packet Processing with Static Routes

## Static Routes and Packet Forwarding (![](./_/M16_StaticForward.png)) 

- PC1 sends a packet to PC3 via the default gateway.
- When the packet reaches R1's `G0/0/0` interface:
  - R1 decapsulates the packet.
  - Searches the routing table for a matching destination network.

### Destination IP Address Matching

- **Matches a static route:**  
  Use the static route to determine the next-hop IP or exit interface.

- **Does not match a specific route:**  
  Use the default static route (if configured).

- **No matching route:**  
  Drop the packet and send an ICMP message back to PC1.

## Forwarding from R1 to R2

- If R1 finds a route:
  - Encapsulates the packet in a new frame.
  - Sends it out `S0/1/0` towards R2.

- R2 receives the packet on `S0/1/0`:
  - Decapsulates it.
  - Searches its routing table for a match.
  - If a match is found, sends the packet out `S0/1/1` towards R3.

## Forwarding from R3 to PC3

- R3 receives the packet:
  - Decapsulates it.
  - Checks the routing table.

- Destination IP matches directly connected `G0/0/0` interface:
  - R3 looks up the ARP table for PC3's MAC address.
  - If no entry exists, R3 sends an ARP request out `G0/0/0`.

- PC3 replies with its MAC address.

- R3 encapsulates the packet:
  - **Destination MAC:** PC3 MAC
  - **Source MAC:** R3 `G0/0/0` MAC

- The frame is sent out `G0/0/0` and PC3 receives the packet.

# 16.2 Troubleshoot IPv4 Static and Default Route Configuration

## Network Changes

Networks can fail for several reasons:

- An interface can fail.
- A service provider may drop a connection.
- Links can become oversaturated.
- An administrator may enter an incorrect configuration.

**Responsibility:** Network administrators must identify and resolve these issues.  

**Tip:** Be familiar with troubleshooting tools to quickly isolate routing problems.

## Common Troubleshooting Commands

| Command                  | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| `ping`                   | Verify Layer 3 connectivity to a destination. Extended pings provide extra options. |
| `traceroute`             | Verify the path to a destination network using ICMP echo reply messages for each hop. |
| `show ip route`          | Display the routing table. Used to check route entries for destination IPs. |
| `show ip interface brief`| Display interface status. Verify operational status and IP addresses. |
| `show cdp neighbors`     | Display directly connected Cisco devices. Validate Layer 1 and Layer 2 connectivity. |

## Solving a Connectivity Problem

**Scenario:** Connectivity from PC1 to PC3 fails.

**Observations:**

- Extended pings from R1 `G0/0/0` to PC3 fail.
- Pings from R1 `S0/1/0` to R2 succeed.
- Pings from R1 `S0/1/0` to R3 succeed.

**Troubleshooting Steps:**

- Check R2's routing table.
- Identify and remove the incorrect static route.

**Solution:**

- Add the correct static route:

```
ip route 172.16.3.0 255.255.255.0 172.16.2.1
```