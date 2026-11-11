#!/usr/bin/env bash
# checks/network.sh - scan other devices on your LAN for risky open ports
# Uses ping for discovery (falls back to bash TCP if ping is missing).
# Reads /proc, so it needs no ip/hostname/nmap.
# Sends network traffic. Only run on networks you own or have permission to test.

[[ -r /proc/net/route && -r /proc/net/arp ]] || { echo "[SKIP] Needs Linux (/proc/net)."; exit 0; }
command -v timeout >/dev/null || { echo "[SKIP] 'timeout' not found (install coreutils)."; exit 0; }

PORTS="21 23 25 80 139 445 3306 3389 5432 5900 6379 8080 27017"

declare -A WHY=(
  [21]="FTP sends passwords in plain text"
  [23]="Telnet sends everything in plain text"
  [25]="SMTP mail server exposed"
  [80]="Unencrypted web interface"
  [139]="NetBIOS/SMB file sharing"
  [445]="SMB file sharing (common ransomware target)"
  [3306]="MySQL database exposed"
  [3389]="Remote Desktop exposed"
  [5432]="PostgreSQL database exposed"
  [5900]="VNC remote screen, often weakly protected"
  [6379]="Redis, often has no password"
  [8080]="Alternate web interface, often an admin panel"
  [27017]="MongoDB, often has no password"
)

hex2ip() { printf '%d.%d.%d.%d' "0x${1:6:2}" "0x${1:4:2}" "0x${1:2:2}" "0x${1:0:2}"; }

# First directly-connected network, skipping docker/VPN/virtual and link-local routes
read -r iface dest mask < <(awk 'NR>1 && $2!="00000000" && $2!="0000FEA9" && $3=="00000000" && $1 !~ /^(lo|docker|virbr|br-|veth|tun|tap|wg|tailscale)/ {print $1, $2, $8; exit}' /proc/net/route)

if [[ -z "$iface" ]]; then
  echo "[SKIP] Not connected to a network."
  exit 0
fi

net=$(hex2ip "$dest")
echo "Scanning network: $net on $iface"

# Discovery: a ping sweep fills the ARP table (/24 only)
if [[ "$mask" == "00FFFFFF" ]]; then
  prefix=${net%.*}
  if command -v ping >/dev/null; then
    for i in $(seq 1 254); do
      ping -c1 -W1 "$prefix.$i" >/dev/null 2>&1 &
    done
  else
    echo "[INFO] 'ping' not found, using connection attempts instead."
    for i in $(seq 1 254); do
      timeout 1 bash -c "echo >/dev/tcp/$prefix.$i/80" 2>/dev/null &
    done
  fi
  wait
else
  echo "[INFO] Network isn't a /24, so only devices already known to this machine are scanned."
fi

# Live devices on this interface (flag 0x0 = no answer, so skip those)
hosts=$(awk -v dev="$iface" 'NR>1 && $3!="0x0" && $6==dev {print $1}' /proc/net/arp | sort -u)

if [[ -z "$hosts" ]]; then
  echo "[OK] No other devices found."
  exit 0
fi

# Default gateway (your router) on this interface
gw=$(awk -v dev="$iface" 'NR>1 && $1==dev && $2=="00000000" {print $3; exit}' /proc/net/route)
[[ -n "$gw" ]] && gw=$(hex2ip "$gw")

echo "Found $(wc -l <<< "$hosts") device(s):"
for h in $hosts; do
  mac=$(awk -v ip="$h" '$1==ip {print $4}' /proc/net/arp)
  name=""
  if command -v getent >/dev/null; then
    name=$(timeout 1 getent hosts "$h" 2>/dev/null | awk '{print $2; exit}')
  fi
  label=""
  [[ "$h" == "$gw" ]] && label="  <- router"
  printf '  %-15s  %s  %s%s\n' "$h" "$mac" "${name:--}" "$label"
done
echo "Checking ports..."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

scan_host() {
  local host=$1 port
  for port in $PORTS; do
    if timeout 1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
      echo "[WARN] $host has port $port open: ${WHY[$port]}" >> "$tmp/$host"
      echo "       Fix: close or disable this service on that device, or block it in its firewall." >> "$tmp/$host"
    fi
  done
}

for h in $hosts; do
  scan_host "$h" &
done
wait

found=0
for f in "$tmp"/*; do
  [[ -e "$f" ]] || continue
  cat "$f"
  found=1
done

if ((found == 0)); then
  echo "[OK] No risky ports found on other devices."
fi