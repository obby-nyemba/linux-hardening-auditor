#!/usr/bin/env bash
# audit.sh — Linux Hardening Auditor
# Runs a set of read-only security checks and reports a score with fixes.
#
# Usage: ./audit.sh
# Safe to run as a normal user; some checks (permissions scan) are deeper
# with sudo but the script will skip gracefully if not run as root.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/report.sh"
source "$SCRIPT_DIR/checks/ssh.sh"
source "$SCRIPT_DIR/checks/firewall.sh"
source "$SCRIPT_DIR/checks/ports.sh"

echo -e "${BOLD}Linux Hardening Auditor${NC}"
echo "Host: $(hostname)  |  Date: $(date)"

check_ssh
check_firewall
check_ports

print_summary
