# Linux Hardening Auditor

A small, dependency-free bash tool that audits a Linux machine for common
security misconfigurations and tells you exactly how to fix each one.

No Docker, no Python, no agents — just bash and the tools already on your
system (`ss`, `grep`, `ufw`/`firewalld`/`iptables`, `pacman`/`apt`/`dnf`).

$ ./audit.sh

Linux Hardening Auditor
Host: arch-vivobook | Date: Mon Nov 10 2026

== SSH Configuration ==
✅ PASS Root login over SSH is disabled
⚠️ WARN Password authentication is enabled
Fix: Set up SSH keys, then set ‘PasswordAuthentication no’ in /etc/ssh/sshd_config
✅ PASS Empty passwords are not permitted over SSH

== Firewall ==
✅ PASS ufw is active

== Open Listening Ports ==
Listening TCP ports: 22 631

== Pending Updates ==
⚠️ WARN 3 package update(s) available
Fix: Run: sudo pacman -Syu
==================================
Score: 5/6 checks passed


## Quickstart

```bash
git clone https://github.com/obby-nyemba/linux-hardening-auditor.git
cd linux-hardening-auditor
chmod +x audit.sh checks/*.sh lib/*.sh
./audit.sh
```

Runs fine as a normal user. No sudo required.

## What it checks

| Check | What it looks for |
|---|---|
| SSH | Root login allowed, password auth allowed, empty passwords permitted |
| Firewall | Whether ufw / firewalld / nftables / iptables is active |
| Open ports | Listening TCP ports, flags commonly-risky ones (Telnet, FTP, RDP, Redis, etc.) |
| Pending updates | Outstanding package updates (pacman, apt, or dnf — auto-detected) |

## Planned checks (good first issues)

- World-writable files outside expected directories
- Users with empty passwords (`/etc/shadow`)
- `NOPASSWD` entries in sudoers
- Kernel version vs. current stable

See [CONTRIBUTING.md](CONTRIBUTING.md) — each check is a single file under
`checks/`, so adding one is self-contained.

## Design goals

- **Zero dependencies** beyond bash and standard Linux tools
- **Explains, not just flags** — every warning includes the exact fix command
- **Read-only** — never changes your system, only reports on it
- **Distro-aware** where it matters (pacman vs apt vs dnf, etc.)

## Releases

See the [Releases page](../../releases) for version history and what changed
in each one.

## License

MIT — see [LICENSE](LICENSE).

