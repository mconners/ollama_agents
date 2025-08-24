# OpenWRT Static IP Configuration Guide

## 🎯 Objective
Configure static DHCP reservations for Ollama cluster nodes to ensure consistent IP addresses.

## 🌐 Web Interface Method (Recommended)

### Access OpenWRT Admin Panel
1. Open browser and go to: **http://192.168.1.1**
2. Login with admin credentials
3. Navigate to: **Network → DHCP and DNS → Static Leases**

### Add Static DHCP Reservations

Click "Add" and configure each node:

| Hostname | MAC Address | IP Address | Description |
|----------|-------------|------------|-------------|
| pi51 | 2c:cf:67:37:e1:9a | 192.168.1.51 | Gateway & Load Balancer |
| pi52 | 2c:cf:67:2e:75:29 | 192.168.1.52 | Backend Services |
| agx0 | 3c:6d:66:33:ce:58 | 192.168.1.150 | Primary AI Hub |
| orin0 | 74:04:f1:c2:1e:56 | 192.168.1.149 | Secondary AI & Image Gen |
| pi41 | dc:a6:32:2b:30:37 | 192.168.1.41 | Utility Services |
| nano | 00:e0:4c:4b:20:d6 | 192.168.1.191 | Edge Inference |
| pi31 | b8:27:eb:af:d4:69 | 192.168.1.31 | Legacy Services |

### Apply Configuration
1. Click **"Save & Apply"** after adding all reservations
2. Restart DHCP service: **System → Startup → dnsmasq → Restart**

## 🖥️ SSH/CLI Method (Alternative)

If you have SSH access to the router:

```bash
# SSH into router
ssh root@192.168.1.1

# Add static DHCP reservations
uci add dhcp host
uci set dhcp.@host[-1].name='pi51'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='2c:cf:67:37:e1:9a'
uci set dhcp.@host[-1].ip='192.168.1.51'

uci add dhcp host
uci set dhcp.@host[-1].name='pi52'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='2c:cf:67:2e:75:29'
uci set dhcp.@host[-1].ip='192.168.1.52'

uci add dhcp host
uci set dhcp.@host[-1].name='agx0'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='3c:6d:66:33:ce:58'
uci set dhcp.@host[-1].ip='192.168.1.150'

uci add dhcp host
uci set dhcp.@host[-1].name='orin0'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='74:04:f1:c2:1e:56'
uci set dhcp.@host[-1].ip='192.168.1.149'

uci add dhcp host
uci set dhcp.@host[-1].name='pi41'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='dc:a6:32:2b:30:37'
uci set dhcp.@host[-1].ip='192.168.1.41'

uci add dhcp host
uci set dhcp.@host[-1].name='nano'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='00:e0:4c:4b:20:d6'
uci set dhcp.@host[-1].ip='192.168.1.191'

uci add dhcp host
uci set dhcp.@host[-1].name='pi31'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='b8:27:eb:af:d4:69'
uci set dhcp.@host[-1].ip='192.168.1.31'

# Commit changes and restart DHCP
uci commit dhcp
/etc/init.d/dnsmasq restart
```

## 🔄 After Configuration

### Renew DHCP Leases on Cluster Nodes

SSH to each node and renew its DHCP lease:

```bash
# Method 1: Release and renew DHCP lease
sudo dhclient -r && sudo dhclient

# Method 2: Restart networking
sudo systemctl restart networking

# Method 3: Reboot (most reliable)
sudo reboot
```

### Verify Static IPs

After 2-3 minutes, check that nodes have the new static IPs:

```bash
# Test connectivity to new static IPs
ping 192.168.1.51   # pi51
ping 192.168.1.52   # pi52  
ping 192.168.1.150  # agx0
ping 192.168.1.149  # orin0
ping 192.168.1.41   # pi41
ping 192.168.1.191  # nano
ping 192.168.1.31   # pi31
```

## ✅ Benefits of Static IPs

- **Consistent addressing**: No more IP address changes
- **Reliable automation**: Deployment scripts always work
- **Better security**: Firewall rules and access control
- **Easier troubleshooting**: Predictable network layout
- **DNS resolution**: Hostnames resolve consistently

## 🔧 Troubleshooting

### If a node doesn't get the static IP:
1. Check MAC address is correct in OpenWRT config
2. Release DHCP lease: `sudo dhclient -r`
3. Renew DHCP lease: `sudo dhclient`
4. Reboot the node if necessary

### If OpenWRT web interface is inaccessible:
1. Check router connection: `ping 192.168.1.1`
2. Try different browser or incognito mode
3. Clear browser cache and cookies
4. Factory reset router if necessary (last resort)

### Check current DHCP leases:
In OpenWRT web interface: **Status → Overview → DHCP Leases**
