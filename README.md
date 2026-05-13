# SRE Learning Labs
Hands-on DevOps/SRE practice labs — 90 days of real break/fix scenarios.
Built while transitioning from 14+ years of product support to SRE engineering.

## Philosophy
No theory without hands-on. Every concept is learned by breaking something
and investigating it — exactly like real on-call work.

## Lab Structure
Each day contains:
- NOTES.md    — theory and concepts explained plainly
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
Key insight: /proc/PID/syscall showing "running" = pure CPU spin.
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

### Day 4 — Bash Scripting
Skills: bash, cron, curl (Slack alerts), color output
Key labs:
- health.sh — CPU/memory/disk/inode/service/log checks with color output
- Slack alerting via webhook when thresholds breached
- Cron scheduling — */5 * * * * every 5 minutes
Key insight: A health script is only useful if it alerts someone.
Threshold tuning matters — too sensitive = alert fatigue.

---

### Day 5 — Systemd Service Management
Skills: systemctl, journalctl, unit files, cgroups
Key labs:
- Created Flask app as systemd service with auto-restart
- StartLimitBurst — systemd stops restarting after N crashes
- reset-failed workflow — how to recover a failed service
- MemoryMax — cgroup memory limits, OOM kill behaviour
Key insight: Restart=on-failure does NOT restart on clean exit (code 0).
reset-failed is required before systemd will restart a failed service again.

---

### Day 6 — Docker Fundamentals
Skills: docker run/exec/logs/stop/rm/rmi, volumes, Dockerfile
Key labs:
- Container ephemerality — data lost on rm, volumes survive
- Port mapping — host:container direction, -p 8080:5000
- Built custom image with Dockerfile (myapp:v1)
- docker exec — getting inside a running container
Key insight: Containers are ephemeral by design.
-v flag is the only way to persist data across container lifecycles.

---

### Day 7 — Docker Networking + Compose
Skills: docker-compose, bridge networks, service discovery
Key labs:
- 3-container app: nginx(8888:80) → api(5000) → redis
- Auto-created bridge network — service names as DNS hostnames
- Break labs: 502 Bad Gateway vs Connection Refused — different causes
Key insight: 502 = upstream reachable but sick.
Connection Refused = nothing listening at that address/port.

---

### Day 8 — Dockerfile Best Practices
Skills: multi-stage builds, layer caching, security scanning
Key labs:
- Bad image (1.62GB) vs good image (210MB) — slim base, .dockerignore
- Layer cache ordering — COPY requirements.txt before COPY . .
- Non-root USER appuser — defence in depth
- Trivy CVE scanning — pinned digests, CRITICAL exit code
Key insight: Layer cache is invalidated top-to-bottom.
requirements.txt copied first = pip install only re-runs when deps change.

---

### Day 9 — Git Workflows + CI/CD
Skills: git, GitHub Actions, DockerHub, branch protection
Key labs:
- Full CI pipeline: test → build → security scan → DockerHub push
- Break lab 1: failing test — pipeline failed at test stage correctly
- Break lab 2: bad Dockerfile COPY — pipeline failed at build stage
- Feature branch → PR → merge with CI gating
- Rebase: linear history, no merge commit forks
- Cherry-pick: single commit applied across branches
- git bisect: found guilty commit in 2 steps across 8 releases
- Interactive rebase: 3 WIP commits squashed into 1 clean commit
- Pre-commit hook: blocked debug print() from being committed
- PR protection rules: merge button blocked until all checks pass
Key insight: CI on PRs means broken code can never reach main.
git bisect turns a 64-commit investigation into 6 yes/no answers.

Repos:
- github.com/gdubey12/sre-cicd-app
- DockerHub: gaurav0524/sre-cicd-app

---

### Day 10 — Docker Compose Advanced
Skills: healthchecks, volumes, postgres, compose overrides
Key labs:
- Health checks: redis-cli ping, pg_isready — condition: service_healthy
- PostgreSQL volume persistence — data survived docker rm + recreate
- DB crash simulation — kill 1, observed restart and health recovery
- Dev vs prod override — docker-compose.override.yml vs docker-compose.prod.yml
Key insight: depends_on without healthcheck only waits for container start.
condition: service_healthy waits for the service inside to actually be ready.

---


### Day 11 — Full Multi-Service Compose App
Skills: flask + postgres + redis + nginx, full stack compose
Key labs:
- Built complete production-like stack from scratch
- Flask API writing to postgres (durability) and redis (speed)
- nginx reverse proxy — single entry point, upstream group, timeout config
- All services health checked — startup order enforced
- Break lab: redis crash → 500 on /visit, partial write to postgres
- Recovery: redis restarted, full stack restored automatically
Key insight: redis is fast and approximate — resets on restart.
Postgres is permanent truth — survived redis crash with full visit history.
Partial write problem: postgres wrote, redis failed mid-transaction → data inconsistency.



# Day 12 | CI/CD Advanced | Matrix builds (3.10/3.11/3.12), pip caching, tests-complete gate, failure notifications via webhook |
## Overview

Extended the GitHub Actions CI/CD pipeline with production-grade features:
matrix builds across Python versions, pip dependency caching, and automated
failure notifications.

## What Was Built

### Matrix Builds
Tests run in parallel across Python 3.10, 3.11, and 3.12 simultaneously.
Catches version-specific compatibility bugs before they reach production.

### Pip Caching
Dependencies cached using `actions/cache@v4`. Cache key is tied to the OS,
Python version, and `requirements.txt` hash — cache invalidates automatically
when dependencies change.

### tests-complete Summary Job
A lightweight gate job that waits for all matrix versions to pass before
reporting a single stable status check. Required for branch protection rules
to work correctly with matrix pipelines.

### Failure Notifications
`notify-on-failure` job fires automatically when any critical job fails.
Sends a JSON payload with repo, branch, commit SHA, and direct run URL
to a webhook endpoint (webhook.site for testing; Slack/PagerDuty in production).

## Pipeline Flow

```
Matrix: Run Tests (3.10 | 3.11 | 3.12)
    ├──→ tests-complete          ← PR gate
    └──→ Build Docker Image
              └──→ Security Scan (Trivy, CRITICAL CVEs)
                        └──→ Push to DockerHub (main only)

[any failure] → Notify on Failure → webhook alert
```

## Key Files

| File | Purpose |
|---|---|
| `.github/workflows/ci.yml` | Full pipeline definition |
| `Dockerfile` | Production image — python:3.11-slim |
| `test_app.py` | pytest tests — verified on 3 Python versions |
| `requirements.txt` | pip cache key source |

## Break Labs Completed

| Lab | What broke | What fired |
|---|---|---|
| Intentional test failure | All 3 matrix jobs failed | notify-on-failure → webhook.site |

## DockerHub

Image: `gaurav0524/sre-cicd-app`
- Tagged with commit SHA for traceability
- `latest` tag updated on every main push
- Verified with `docker pull` + `curl /health` on local VM

## Lessons Learned

- Matrix builds change job names — always use a summary job as PR gate
- Cache step must come BEFORE install dependencies to be useful
- `if: failure()` is edge-triggered — only fires when something actually broke
- `github.sha` tagging gives full rollback capability; `latest` does not

### Day 13 — Monitoring Basics
- journalctl: system log filtering by service, time window, boot boundary
- docker compose logs: follow mode, time window filtering
- docker stats: live CPU/MEM/NET — mapped to counter vs gauge metric types
- Docker bridge networking: br-* interfaces, veth pairs, gateway IP
- Runbook: [monitoring-basics.md](labs/day13/runbooks/monitoring-basics.md)





---
## Tools Used
Linux: ps, top, lsof, strace, df, du, ss, tcpdump, nc, curl
Networking: iptables, firewalld, nmap
Scripting: bash, python3
Docker: docker, docker compose, Dockerfile, trivy
CI/CD: GitHub Actions, DockerHub
Git: rebase, cherry-pick, bisect, interactive rebase, pre-commit hooks

## Environment
VM 1: Ubuntu 22.04 LTS — 192.168.31.21
VM 2: CentOS Stream 9  — 192.168.31.158
Host: Windows 11, Ryzen 5 5500U, 16GB RAM

## Background
14+ years in product support transitioning to SRE engineering.
Every runbook written from real hands-on investigation, not copied from docs.
