# Contributing

Thanks for considering a contribution! This project is intentionally small
and beginner-friendly to add to.

## Adding a new check

1. Create a new file in `checks/`, e.g. `checks/updates.sh`.
2. Define a single function, e.g. `check_updates()`.
3. Inside it, call `section "Your Section Name"` first, then for each
   individual test call one of:
   - `pass "message"` — the check is good
   - `warn "message" "fix command"` — not ideal, but not critical
   - `fail "message" "fix command"` — a real problem
4. Source your file and call your function from `audit.sh`.

Keep each check:
- **Read-only** — never modify the system in v1
- **Dependency-light** — prefer tools already on most systems; if you need
  something uncommon, check with `command -v` and warn gracefully if missing
- **Distro-aware when needed** — e.g. detect pacman vs apt vs dnf rather
  than assuming one

## Good first issues

- Pending security updates check (pacman/apt/dnf aware)
- World-writable file scan outside expected directories
- Sudoers NOPASSWD detection
- Kernel version vs. latest stable comparison
- JSON output mode (`--json` flag) for scripting/CI use

## Testing your check

Run `./audit.sh` locally before opening a PR. If your check behaves
differently across distros, mention that in the PR description.
