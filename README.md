# Linux Hardening Auditor

A read-only security checker for Linux. It runs a set of checks, tells you what's weak, and gives you the exact command to fix each problem. It ends with a score.

## Quick start

```
git clone https://github.com/YOURUSERNAME/REPONAME.git
cd REPONAME
chmod +x audit.sh
./audit.sh
```

To also scan other devices on your network:

```
./audit.sh --network
```

Only use `--network` on networks you own or have permission to test. It sends connection attempts to other devices.

Safe to run as a normal user. Some checks go deeper with `sudo`, and the script skips gracefully if you're not root.

## What it checks

| Check | What it looks at |
|---|---|
| SSH | Root login allowed, password auth allowed, empty passwords permitted |
| Firewall | Whether ufw / firewalld / nftables / iptables is active |
| Open ports | Listening TCP ports, flags commonly-risky ones (Telnet, FTP, RDP, Redis, etc.) |
| Pending updates | Outstanding package updates (pacman, apt, or dnf, auto-detected) |
| Network devices | Opt-in with `--network`. Lists other devices on your LAN and flags risky open ports (Telnet, FTP, RDP, Redis, etc.) |

## Example output

```
Linux Hardening Auditor
Host: mypc  |  Date: Wed Nov 11 2026

== SSH Configuration ==
✅ PASS  Root login over SSH is disabled
⚠️  WARN  Password authentication is enabled
         Fix: Set up SSH keys, then set 'PasswordAuthentication no' in /etc/ssh/sshd_config

==================================
Score: 1/2 checks passed
==================================
```

Every warning includes a `Fix:` line with what to change.

## Network scan (opt-in)

`./audit.sh --network` adds a "Network Devices" section. It:

- finds your local network and the other devices on it,
- lists each device with its IP, MAC address and hostname (your router is tagged),
- checks each device for 13 commonly risky open ports,
- adds the results to your score.

It needs only bash and standard Linux tools. If `nmap` is installed, it uses it for faster and more accurate port scanning, and it uses `ping` for discovery when available. Without them it falls back to plain bash connections.


Limits: devices that are asleep or isolated by the router (common on phone hotspots and guest Wi-Fi) won't show up, and it only checks common ports, not all 65,535.For a full scan of all ports on one device, run `nmap -p- DEVICE_IP` yourself.


You can also run it on its own: `./checks/network.sh`

## Planned checks (good first issues)

- World-writable files outside expected directories
- Users with empty passwords (`/etc/shadow`)
- `NOPASSWD` entries in sudoers
- Kernel version vs. current stable

See [CONTRIBUTING.md](CONTRIBUTING.md). Each check is a single file under `checks/`, so adding one is self-contained.

## Design goals

- **Zero dependencies** beyond bash and standard Linux tools
- **Explains, not just flags**: every warning includes the exact fix command
- **Read-only**: never changes your system, only reports on it
- **Distro-aware** where it matters (pacman vs apt vs dnf, etc.)

## Releases

See the [Releases page](https://github.com/YOURUSERNAME/REPONAME/releases) for version history and what changed in each one.

## License

MIT, see [LICENSE](LICENSE).