# SRE Learning Labs

Hands-on DevOps/SRE practice labs — 90 days of real break/fix scenarios.

## What this is
Practical labs built while learning SRE from scratch with 14+ years of product support background. Every lab has a real break scenario, investigation methodology, and a runbook written from actual hands-on experience.

## Structure
Each day folder contains:
- `break.sh` — injects the failure
- `runbooks/` — written after investigating and fixing

## Labs completed

### Day 1 — Process Investigation
- CPU spin loop detection using /proc/syscall
- Zombie process identification and cleanup
- DB wait simulation — recvfrom() syscall signature
- Tools: ps, lsof, /proc, kill signals

### Day 2 — Disk Triage
- Disk full recovery without reboot
- Deleted file still holding space (truncate trick)
- Inode exhaustion — df -h shows free but writes fail
- Tools: df, du, lsof, truncate

## Tools used
Linux, Python, bash, ps, lsof, strace, tcpdump, iptables, ss, df, du

## Background
14+ years product support → learning the engineering side
