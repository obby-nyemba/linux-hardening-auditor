# Linux Hardening Auditor

A small, dependency-free bash tool that audits a Linux machine for common
security misconfigurations and tells you exactly how to fix each one.

No Docker, no Python, no agents — just bash and the tools already on your
system (`ss`, `grep`, `ufw`/`firewalld`/`iptables`).

```
$ ./audit.sh

Linux Hardening Auditor
Host: arch-vivobook  |  Date: Mon Nov 9 2026

== SSH Configuration ==
✅ PASS  Root login over SSH is disabled
⚠️  WARN  Password authentication is enabled
         Fix: Set up SSH keys, then set 'PasswordAuthentication no' in /etc/ssh/sshd_config
✅ PASS  Empty passwords are not permitted over SSH

== Firewall ==
✅ PASS  ufw is active

== Open Listening Ports ==
  Listening TCP ports: 22 631

==================================
Score: 4/5 checks passed
==================================
```

## Quickstart

```bash
git clone https://github.com/<your-username>/linux-hardening-auditor.git
cd linux-hardening-auditor
chmod +x audit.sh
./audit.sh
```

Runs fine as a normal user. No sudo required for v1's checks.

## What it checks (v1)

| Check | What it looks for |
|---|---|
| SSH | Root login allowed, password auth allowed, empty passwords permitted |
| Firewall | Whether ufw / firewalld / nftables / iptables is active |
| Open ports | Listening TCP ports, flags commonly-risky ones (Telnet, FTP, RDP, Redis, etc.) |

## Planned checks (good first issues)

- World-writable files outside expected directories
- Users with empty passwords (`/etc/shadow`)
- `NOPASSWD` entries in sudoers
- Pending security updates (distro-aware: pacman/apt/dnf)
- Kernel version vs. current stable

See [CONTRIBUTING.md](CONTRIBUTING.md) — each check is a single file under
`checks/`, so adding one is self-contained.

## Design goals

- **Zero dependencies** beyond bash and standard Linux tools
- **Explains, not just flags** — every warning includes the exact fix command
- **Read-only** — v1 never changes your system, only reports on it
- **Distro-aware** where it matters (Arch/Debian package manager differences, etc.)

## License

MIT — see [LICENSE](LICENSE).
