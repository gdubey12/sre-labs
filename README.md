# SRE Learning Labs

Hands-on DevOps/SRE practice labs — 90 days of real break/fix scenarios.
Built while transitioning from 14+ years of product support to SRE engineering.

## Philosophy
No theory without hands-on. Every concept is learned by breaking something
and investigating it — exactly like real on-call work.

## Lab Structure
Each day contains:
- NOTES.md    — theory and concepts explained plainly
- break.sh    — script that injects the failure
- runbooks/   — written after investigating and fixing

## Reference Materials
- reference/syscall-reference.md — syscall numbers for incident investigation

---

## Labs Completed

### Day 1 — Process Investigation
Skills: ps, /proc, lsof, strace, kill signals

Key labs:
- CPU spin loop detection — found rogue process using /proc/syscall
- Zombie process investigation — why kill -9 fails, how to fix it
- DB wait simulation — recvfrom() signature, TCP socket investigation

Key insight: /proc/PID/syscall showing running = pure CPU spin.
Syscall 45 recvfrom + TCP to port 5432 = app waiting on DB, not broken.

---

### Day 2 — Disk Triage
Skills: df, du, lsof, truncate, inode management

Key labs:
- Disk full recovery — filled /home to 100%, recovered without reboot
- Deleted file trick — file deleted but space not freed, found with lsof
- Inode exhaustion — 1.2M files consumed all inodes with only 87MB disk used

Key insight: df -h showing free space does NOT mean writes will succeed.
Always run df -i separately. Two different limits, same error message.

---

### Day 3 — Network Debugging
Skills: curl, tcpdump, iptables, firewalld, ss, nc

Key labs:
- Connection refused vs timeout — instant vs slow failure, different causes
- Local firewall DROP — OUTPUT chain, tcpdump shows nothing
- Remote firewall DROP — SYN goes out, no SYN-ACK, firewalld blocking
- Live tcpdump analysis — reading full TCP handshake in real time

Key insight: tcpdump shows nothing = local iptables OUTPUT drop.
tcpdump shows SYN but no SYN-ACK = remote firewall dropping.

Used 2 VMs: Ubuntu 22.04 client + CentOS Stream 9 server.

---

## Tools Used
Linux: ps, top, lsof, strace, df, du, ss, tcpdump, nc, curl
Networking: iptables, firewalld, nmap
Scripting: bash, python3

## Environment
VM 1: Ubuntu 22.04 LTS — 192.168.31.21
VM 2: CentOS Stream 9  — 192.168.31.158
Host: Windows 11, Ryzen 5 5500U, 16GB RAM

## Background
14+ years in product support transitioning to SRE engineering.
Every runbook written from real hands-on investigation, not copied from docs.
