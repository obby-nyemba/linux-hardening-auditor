#!/usr/bin/env bash
# checks/updates.sh — checks for pending package updates
# Distro-aware: supports pacman (Arch), apt (Debian/Ubuntu), dnf (Fedora/RHEL)

check_updates() {
    section "Pending Updates"

    if command -v pacman >/dev/null 2>&1; then
        _check_updates_pacman
    elif command -v apt >/dev/null 2>&1; then
        _check_updates_apt
    elif command -v dnf >/dev/null 2>&1; then
        _check_updates_dnf
    else
        warn "No supported package manager found (pacman, apt, dnf)" \
             "This check currently supports Arch, Debian/Ubuntu, and Fedora/RHEL"
    fi
}

_check_updates_pacman() {
    if ! command -v checkupdates >/dev/null 2>&1; then
        warn "checkupdates not found (part of pacman-contrib)" \
             "Install with: sudo pacman -S pacman-contrib"
        return
    fi

    local count
    count=$(checkupdates 2>/dev/null | wc -l)

    if [ "$count" -eq 0 ]; then
        pass "System is up to date (pacman)"
    elif [ "$count" -le 10 ]; then
        warn "$count package update(s) available" "Run: sudo pacman -Syu"
    else
        fail "$count package updates available — system is significantly behind" \
             "Run: sudo pacman -Syu"
    fi
}

_check_updates_apt() {
    # apt list --upgradable requires an up-to-date index; we don't run
    # 'apt update' ourselves since that would modify system state.
    local count
    count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")

    if [ "$count" -eq 0 ]; then
        pass "System is up to date (apt), based on the last 'apt update'"
    elif [ "$count" -le 10 ]; then
        warn "$count package update(s) available" "Run: sudo apt update && sudo apt upgrade"
    else
        fail "$count package updates available — system is significantly behind" \
             "Run: sudo apt update && sudo apt upgrade"
    fi
}

_check_updates_dnf() {
    local count
    count=$(dnf check-update --quiet 2>/dev/null | grep -cE "^\S+\s+\S+\s+\S+$")

    if [ "$count" -eq 0 ]; then
        pass "System is up to date (dnf)"
    elif [ "$count" -le 10 ]; then
        warn "$count package update(s) available" "Run: sudo dnf upgrade"
    else
        fail "$count package updates available — system is significantly behind" \
             "Run: sudo dnf upgrade"
    fi
}