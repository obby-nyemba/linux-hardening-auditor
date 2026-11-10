#!/usr/bin/env bash
# checks/firewall.sh — checks whether a firewall is active

check_firewall() {
    section "Firewall"

    if command -v ufw >/dev/null 2>&1; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            pass "ufw is active"
            return
        else
            fail "ufw is installed but not active" "Run: sudo ufw enable"
            return
        fi
    fi

    if command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state 2>/dev/null | grep -q "running"; then
            pass "firewalld is active"
            return
        else
            fail "firewalld is installed but not running" \
                 "Run: sudo systemctl enable --now firewalld"
            return
        fi
    fi

    if command -v nft >/dev/null 2>&1; then
        local rule_count
        rule_count=$(nft list ruleset 2>/dev/null | grep -c "chain")
        if [ "$rule_count" -gt 0 ]; then
            pass "nftables has active rules ($rule_count chains found)"
            return
        fi
    fi

    if command -v iptables >/dev/null 2>&1; then
        local rule_count
        rule_count=$(iptables -L 2>/dev/null | grep -cE "^(ACCEPT|DROP|REJECT)")
        if [ "$rule_count" -gt 0 ]; then
            pass "iptables has active rules ($rule_count rules found)"
            return
        else
            warn "iptables is present but has no obvious rules set" \
                 "Set up ufw (simplest) or write iptables/nftables rules directly"
            return
        fi
    fi

    fail "No firewall tool found (ufw, firewalld, nftables, iptables)" \
         "Install ufw: sudo pacman -S ufw   (or apt install ufw on Debian/Ubuntu)"
}
