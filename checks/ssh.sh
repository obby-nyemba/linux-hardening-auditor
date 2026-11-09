#!/usr/bin/env bash
# checks/ssh.sh — checks sshd_config for common weak settings

check_ssh() {
    section "SSH Configuration"

    local sshd_config="/etc/ssh/sshd_config"

    if [ ! -f "$sshd_config" ]; then
        warn "sshd_config not found at $sshd_config — SSH may not be installed" ""
        return
    fi

    # Helper: get the effective value of a directive (last match, ignore comments/case)
    get_directive() {
        grep -iE "^\s*$1\s+" "$sshd_config" 2>/dev/null | tail -n1 | awk '{print tolower($2)}'
    }

    local root_login
    root_login=$(get_directive "PermitRootLogin")
    if [ "$root_login" = "no" ]; then
        pass "Root login over SSH is disabled"
    elif [ -z "$root_login" ]; then
        warn "PermitRootLogin not explicitly set (default varies by distro)" \
             "Add 'PermitRootLogin no' to $sshd_config"
    else
        fail "Root login over SSH is allowed (PermitRootLogin $root_login)" \
             "Set 'PermitRootLogin no' in $sshd_config, then restart sshd"
    fi

    local pass_auth
    pass_auth=$(get_directive "PasswordAuthentication")
    if [ "$pass_auth" = "no" ]; then
        pass "Password authentication is disabled (key-only login)"
    elif [ -z "$pass_auth" ]; then
        warn "PasswordAuthentication not explicitly set" \
             "Set 'PasswordAuthentication no' once you have SSH keys working"
    else
        warn "Password authentication is enabled" \
             "Set up SSH keys, then set 'PasswordAuthentication no' in $sshd_config"
    fi

    local empty_pass
    empty_pass=$(get_directive "PermitEmptyPasswords")
    if [ "$empty_pass" = "yes" ]; then
        fail "Empty passwords are permitted over SSH" \
             "Set 'PermitEmptyPasswords no' in $sshd_config"
    else
        pass "Empty passwords are not permitted over SSH"
    fi
}
