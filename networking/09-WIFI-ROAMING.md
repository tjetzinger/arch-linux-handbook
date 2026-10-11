# 09 - WiFi Roaming (Mesh AP Flip-Flopping)

Reduce unnecessary AP switching on Fritz!Box mesh networks with 4 APs.

## Problem

NetworkManager's default `wpa_supplicant` bgscan setting (`simple:30:-65:300`) triggers background scans every 5 minutes and roams whenever a slightly stronger AP is found. With 4 Fritz!Box mesh APs broadcasting "HomeWifi", this causes roaming every ~40 seconds with brief connectivity drops (DHCP restart each time).

## Solution

Override bgscan via NetworkManager dispatcher script using `wpa_cli`. NetworkManager hardcodes bgscan defaults and doesn't expose this as a configurable option, so a dispatcher script is required.

| Parameter | NM Default | Override | Meaning |
|-----------|-----------|----------|---------|
| Algorithm | `simple` | `simple` | Simple background scan |
| Short interval | `30` s | `30` s | Scan interval when signal is weak |
| Threshold | `-65` dBm | `-70` dBm | Only roam if signal drops below this |
| Long interval | `300` s | `3600` s | Scan interval when signal is good |

## Configuration

**File:** `/etc/NetworkManager/dispatcher.d/90-wifi-bgscan`

```bash
#!/bin/bash
# Reduce AP flip-flopping on Fritz!Box mesh: only roam when signal < -70 dBm
# NM default (simple:30:-65:300) is too aggressive for mesh with 4 APs

IFACE="$1"
ACTION="$2"

[[ "$ACTION" != "up" ]] && exit 0
[[ "$IFACE" != wlan* ]] && exit 0

# NM sets its bgscan after dispatcher fires, so override with a delay
(
    sleep 5
    NETWORK_ID=$(wpa_cli -i "$IFACE" list_networks | awk '/CURRENT/ {print $1}')
    if [[ -n "$NETWORK_ID" ]]; then
        wpa_cli -i "$IFACE" set_network "$NETWORK_ID" bgscan '"simple:30:-70:3600"'
        logger "wifi-bgscan: set simple:30:-70:3600 on $IFACE"
    fi
) &
disown

exit 0
```

```bash
sudo chmod 755 /etc/NetworkManager/dispatcher.d/90-wifi-bgscan
sudo systemctl restart NetworkManager
```

## Verification

```bash
# Confirm bgscan is applied (wait ~10s after wifi connects)
sudo wpa_cli -i wlan0 get_network 0 bgscan
# Expected: "simple:30:-70:3600"

# Check dispatcher ran
journalctl --since "5 minutes ago" | grep wifi-bgscan

# Monitor roaming events (should be much less frequent)
journalctl -u NetworkManager -f | grep -i roam

# Check current AP signal strength
iwconfig wlan0 | grep -i signal
# or
nmcli -f SSID,SIGNAL,BSSID device wifi list
```

## Tuning

If still roaming too often, lower the threshold (more tolerant of weak signal):

| Threshold | Behavior |
|-----------|----------|
| `-65` dBm | NM default, roams aggressively |
| `-70` dBm | Moderate, good for mesh (current) |
| `-75` dBm | Conservative, stays on AP longer |
| `-80` dBm | Very sticky, only roams when signal is poor |

Edit the threshold in `/etc/NetworkManager/dispatcher.d/90-wifi-bgscan` and restart NM.

## Why Not `conf.d`?

NetworkManager does **not** support `wifi.bgscan` as a configuration key in `/etc/NetworkManager/conf.d/`. The `[connection]` section in conf.d files only accepts standard NM properties. The bgscan parameter is hardcoded internally and passed to `wpa_supplicant` via D-Bus, so a dispatcher + `wpa_cli` override is the only reliable approach.

## Related

- [06-TROUBLESHOOTING](./06-TROUBLESHOOTING.md) - General network troubleshooting
- [08-WIFI-HOTSPOT](./08-WIFI-HOTSPOT.md) - WiFi hotspot configuration
