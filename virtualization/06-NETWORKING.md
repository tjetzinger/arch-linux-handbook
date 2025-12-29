# 06 - Networking

VM networking options: NAT, bridged, isolated, and Tailscale integration.

## Network Types

| Type | Use Case | Internet | Host Access | VM-to-VM |
|------|----------|----------|-------------|----------|
| NAT | Default, most VMs | Yes | Yes | Same network |
| Bridged | Server VMs | Yes | Yes | All |
| Isolated | Security testing | No | No | Same network |
| Host-only | Development | No | Yes | Same network |

## Default NAT Network

### Current Configuration

```xml
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

### How NAT Works

```
VM (192.168.122.x)
        │
        ↓
    virbr0 (NAT)
        │
        ↓
    Host (iptables MASQUERADE)
        │
        ↓
    Internet
```

### Manage Default Network

```bash
# Status
virsh net-list --all

# Start/Stop
virsh net-start default
virsh net-destroy default

# Auto-start
virsh net-autostart default
virsh net-autostart --disable default

# View config
virsh net-dumpxml default

# DHCP leases
virsh net-dhcp-leases default
```

## Bridged Networking

### When to Use

- VM needs its own IP on physical network
- Running servers accessible from LAN
- VM needs to be on same subnet as host

### Create Network Bridge

```bash
# Using NetworkManager
nmcli connection add type bridge ifname br0
nmcli connection add type ethernet ifname enp0s31f6 master br0
nmcli connection up br0
```

### Add Bridge to libvirt

```xml
<!-- /etc/libvirt/qemu/networks/bridged.xml -->
<network>
  <name>bridged</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
```

```bash
virsh net-define bridged.xml
virsh net-start bridged
virsh net-autostart bridged
```

### Use in VM

```bash
virt-install ... --network bridge=br0,model=virtio
```

Or in XML:
```xml
<interface type='bridge'>
  <source bridge='br0'/>
  <model type='virtio'/>
</interface>
```

## Isolated Network

### For Security Testing

VMs can talk to each other but not to host or internet.

```xml
<!-- isolated.xml -->
<network>
  <name>isolated</name>
  <ip address='10.0.0.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.0.0.2' end='10.0.0.254'/>
    </dhcp>
  </ip>
</network>
```

```bash
virsh net-define isolated.xml
virsh net-start isolated
```

## Host-Only Network

### VMs Can Reach Host Only

```xml
<!-- hostonly.xml -->
<network>
  <name>hostonly</name>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
```

## Static IP Assignment

### DHCP Reservation

```bash
# Edit network
virsh net-edit default
```

Add inside `<dhcp>`:
```xml
<host mac='52:54:00:62:c1:d8' name='win11' ip='192.168.122.100'/>
```

```bash
# Restart network
virsh net-destroy default
virsh net-start default
```

### Static IP in Guest

Configure inside the VM:

**systemd-networkd:**
```ini
[Match]
Name=enp1s0

[Network]
Address=192.168.122.100/24
Gateway=192.168.122.1
DNS=192.168.122.1
```

## Port Forwarding

### Forward Host Port to VM

Using iptables (manual):
```bash
# Forward host:8080 to VM:80
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 \
    -j DNAT --to-destination 192.168.122.100:80
sudo iptables -A FORWARD -p tcp -d 192.168.122.100 --dport 80 -j ACCEPT
```

### Using libvirt Hooks

Create `/etc/libvirt/hooks/qemu`:
```bash
#!/bin/bash
VM_NAME="$1"
ACTION="$2"

if [ "$VM_NAME" = "webserver" ]; then
    HOST_PORT=8080
    GUEST_IP=192.168.122.100
    GUEST_PORT=80

    if [ "$ACTION" = "started" ]; then
        iptables -t nat -A PREROUTING -p tcp --dport $HOST_PORT \
            -j DNAT --to $GUEST_IP:$GUEST_PORT
    elif [ "$ACTION" = "stopped" ]; then
        iptables -t nat -D PREROUTING -p tcp --dport $HOST_PORT \
            -j DNAT --to $GUEST_IP:$GUEST_PORT
    fi
fi
```

```bash
chmod +x /etc/libvirt/hooks/qemu
systemctl restart libvirtd
```

## Multiple NICs

### Add Second NIC

```bash
# Via virt-manager: Add Hardware > Network

# Via XML
virsh attach-interface win11 --type network --source isolated --model virtio --persistent
```

### XML Example

```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
</interface>
<interface type='network'>
  <source network='isolated'/>
  <model type='virtio'/>
</interface>
```

## Tailscale Integration

### Access VMs via Tailscale

The host already advertises `192.168.122.0/24` via Tailscale subnet routing.

```bash
# Verify on host
tailscale debug prefs | grep AdvertiseRoutes
# Should include 192.168.122.0/24
```

### From Remote Tailscale Device

```bash
# Access VM directly
ssh user@192.168.122.100
curl http://192.168.122.100:8080
```

### Install Tailscale in VM

For VMs that need their own Tailscale identity:

```bash
# In VM
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Benefits:
- VM gets its own Tailscale IP
- Direct connections to other Tailscale devices
- MagicDNS hostname

## DNS in VMs

### libvirt dnsmasq

VMs using NAT get DNS from libvirt's dnsmasq (192.168.122.1).

### Custom DNS

In network definition:
```xml
<dns>
  <forwarder addr='9.9.9.9'/>
  <forwarder addr='1.1.1.1'/>
</dns>
```

### Use Host's DNS

Point VM to host IP:
```bash
# In VM
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

## Network Performance

### VirtIO (Required)

Always use virtio for best performance:
```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
</interface>
```

### Multi-Queue

For high throughput:
```xml
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
  <driver name='vhost' queues='4'/>
</interface>
```

## Firewall Considerations

### UFW on Host

```bash
# Allow VM traffic
sudo ufw allow in on virbr0
sudo ufw allow out on virbr0

# Allow forwarding
sudo ufw route allow in on virbr0
```

### iptables

libvirt manages its own iptables rules. View them:
```bash
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

## Troubleshooting

### VM Has No Network

```bash
# Check network is active
virsh net-list

# Check VM interface
virsh domiflist <vm>

# Check DHCP lease
virsh net-dhcp-leases default

# In VM, check interface
ip addr
ip route
```

### Can't Reach Internet from VM

```bash
# Check NAT/forwarding on host
cat /proc/sys/net/ipv4/ip_forward
# Should be 1

# Check iptables MASQUERADE
sudo iptables -t nat -L POSTROUTING -n -v
```

### DNS Not Working in VM

```bash
# In VM
cat /etc/resolv.conf
ping 192.168.122.1

# Try direct DNS query
dig @192.168.122.1 google.com
```

## Quick Reference

```bash
# Network management
virsh net-list --all
virsh net-start default
virsh net-dumpxml default
virsh net-dhcp-leases default

# VM interfaces
virsh domiflist win11
virsh attach-interface win11 --type network --source default --model virtio

# Create network
virsh net-define network.xml
virsh net-start mynet
virsh net-autostart mynet
```

## Related

- [01-OVERVIEW](./01-OVERVIEW.md) - Network topology
- [../networking/](../networking/) - Tailscale docs
- [08-PERFORMANCE](./08-PERFORMANCE.md) - Network tuning
