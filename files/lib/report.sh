#!/usr/bin/env bash
# lib/report.sh — shared output helpers for all checks
# Sourced by audit.sh; not meant to be run directly.

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Tracks results across the whole run
TOTAL_CHECKS=0
PASSED_CHECKS=0

pass() {
    local msg="$1"
    echo -e "${GREEN}✅ PASS${NC}  $msg"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

warn() {
    local msg="$1"
    local fix="$2"
    echo -e "${YELLOW}⚠️  WARN${NC}  $msg"
    [ -n "$fix" ] && echo -e "         ${BOLD}Fix:${NC} $fix"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

fail() {
    local msg="$1"
    local fix="$2"
    echo -e "${RED}❌ FAIL${NC}  $msg"
    [ -n "$fix" ] && echo -e "         ${BOLD}Fix:${NC} $fix"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

section() {
    echo ""
    echo -e "${BOLD}== $1 ==${NC}"
}

print_summary() {
    echo ""
    echo -e "${BOLD}==================================${NC}"
    echo -e "${BOLD}Score: ${PASSED_CHECKS}/${TOTAL_CHECKS} checks passed${NC}"
    echo -e "${BOLD}==================================${NC}"
}
