#!/usr/bin/env bash
# checks/ports.sh — lists listening ports and flags risky ones

check_ports() {
    section "Open Listening Ports"

    if ! command -v ss >/dev/null 2>&1; then
        warn "'ss' not found, skipping port check" "Install iproute2"
        return
    fi

    # Ports that are commonly risky to expose without good reason
    local risky_ports="23 21 445 3389 6379 27017 9200 5900"

    local listening
    listening=$(ss -tlnH 2>/dev/null | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)

    if [ -z "$listening" ]; then
        pass "No TCP ports are listening"
        return
    fi

    echo "  Listening TCP ports: $(echo "$listening" | tr '\n' ' ')"

    local found_risky=0
    for port in $listening; do
        for risky in $risky_ports; do
            if [ "$port" = "$risky" ]; then
                found_risky=1
                case "$port" in
                    23)   svc="Telnet (unencrypted)";;
                    21)   svc="FTP (often unencrypted)";;
                    445)  svc="SMB";;
                    3389) svc="RDP";;
                    6379) svc="Redis";;
                    27017) svc="MongoDB";;
                    9200) svc="Elasticsearch";;
                    5900) svc="VNC";;
                    *)    svc="service";;
                esac
                warn "Port $port ($svc) is listening — confirm it should be reachable" \
                     "If not needed externally, bind it to 127.0.0.1 or firewall it off"
            fi
        done
    done

    if [ "$found_risky" -eq 0 ]; then
        pass "No commonly-risky ports found among listening services"
    fi
}
