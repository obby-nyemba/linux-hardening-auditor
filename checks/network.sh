#!/usr/bin/env bash
# checks/network.sh — scans other devices on your LAN for risky open ports
# Opt-in: only runs with ./audit.sh --network
# Needs only bash + coreutils (reads /proc). Uses ping if available.
# Sends network traffic. Only run on networks you own or have permission to test.

net_hex2ip() {
    printf '%d.%d.%d.%d' "0x${1:6:2}" "0x${1:4:2}" "0x${1:2:2}" "0x${1:0:2}"
}

net_why() {
    case "$1" in
        21)    echo "FTP sends passwords in plain text" ;;
        23)    echo "Telnet sends everything in plain text" ;;
        25)    echo "SMTP mail server exposed" ;;
        80)    echo "Unencrypted web interface" ;;
        139)   echo "NetBIOS/SMB file sharing" ;;
        445)   echo "SMB file sharing (common ransomware target)" ;;
        3306)  echo "MySQL database exposed" ;;
        3389)  echo "Remote Desktop exposed" ;;
        5432)  echo "PostgreSQL database exposed" ;;
        5900)  echo "VNC remote screen, often weakly protected" ;;
        6379)  echo "Redis, often has no password" ;;
        8080)  echo "Alternate web interface, often an admin panel" ;;
        27017) echo "MongoDB, often has no password" ;;
    esac
}

check_network() {
    section "Network Devices"

    local ports="21 23 25 80 139 445 3306 3389 5432 5900 6379 8080 27017"

    if [ ! -r /proc/net/route ] || [ ! -r /proc/net/arp ]; then
        echo "  [SKIP] Network scan needs Linux (/proc/net)."
        return
    fi
    if ! command -v timeout >/dev/null 2>&1; then
        echo "  [SKIP] 'timeout' not found (install coreutils)."
        return
    fi

    # First directly-connected network, skipping docker/VPN/virtual and link-local routes
    local iface="" dest="" mask=""
    read -r iface dest mask < <(awk 'NR>1 && $2!="00000000" && $2!="0000FEA9" && $3=="00000000" && $1 !~ /^(lo|docker|virbr|br-|veth|tun|tap|wg|tailscale)/ {print $1, $2, $8; exit}' /proc/net/route)

    if [ -z "$iface" ]; then
        echo "  [SKIP] Not connected to a network."
        return
    fi

    local net
    net=$(net_hex2ip "$dest")
    echo "  Network: $net on $iface"

    # Discovery: a ping sweep fills the ARP table (/24 networks only)
    local prefix i
    if [ "$mask" = "00FFFFFF" ]; then
        prefix=${net%.*}
        if command -v ping >/dev/null 2>&1; then
            for i in $(seq 1 254); do
                ping -c1 -W1 "$prefix.$i" >/dev/null 2>&1 &
            done
        else
            for i in $(seq 1 254); do
                timeout 1 bash -c "echo >/dev/tcp/$prefix.$i/80" 2>/dev/null &
            done
        fi
        wait
    else
        echo "  [INFO] Not a /24 network, so only devices already known to this machine are scanned."
    fi

    # Live devices on this interface (flag 0x0 = no answer, so skip those)
    local hosts
    hosts=$(awk -v dev="$iface" 'NR>1 && $3!="0x0" && $6==dev {print $1}' /proc/net/arp | sort -u)

    if [ -z "$hosts" ]; then
        echo "  [INFO] No other devices found."
        return
    fi

    # Default gateway (your router)
    local gw
    gw=$(awk -v dev="$iface" 'NR>1 && $1==dev && $2=="00000000" {print $3; exit}' /proc/net/route)
    [ -n "$gw" ] && gw=$(net_hex2ip "$gw")

    local h mac name label
    echo "  Found $(wc -l <<< "$hosts") device(s):"
    for h in $hosts; do
        mac=$(awk -v ip="$h" '$1==ip {print $4}' /proc/net/arp)
        name=""
        if command -v getent >/dev/null 2>&1; then
            name=$(timeout 1 getent hosts "$h" 2>/dev/null | awk '{print $2; exit}')
        fi
        label=""
        [ "$h" = "${gw:-}" ] && label="  <- router"
        printf '    %-15s  %s  %s%s\n' "$h" "$mac" "${name:--}" "$label"
    done
    echo ""

    # Scan every device in parallel; each writes its open ports to its own file
    local tmp p
    tmp=$(mktemp -d)
    for h in $hosts; do
        (
            for p in $ports; do
                if timeout 1 bash -c "echo >/dev/tcp/$h/$p" 2>/dev/null; then
                    echo "$p" >> "$tmp/$h"
                fi
            done
        ) &
    done
    wait

    # Report: one result per device
    for h in $hosts; do
        if [ -s "$tmp/$h" ]; then
            for p in $(sort -n "$tmp/$h"); do
                warn "$h has port $p open: $(net_why "$p")" \
                     "Disable this service on that device, or block port $p in its firewall"
            done
        else
            pass "No risky ports open on $h"
        fi
    done

    rm -rf "$tmp"
}

# Lets you still run this file by itself: ./checks/network.sh
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    source "$(dirname "$0")/../lib/report.sh"
    check_network
    print_summary
fi