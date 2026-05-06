# Day 5 — Systemd Service Management

## What is systemd?
Systemd is PID 1 — the first process Linux starts on boot.
It manages all other services: starts them, restarts on crash,
limits resources, and logs everything.

Think of it as a hospital administrator:
- Knows which departments open first (dependencies)
- Monitors every department (service watching)
- Reopens crashed departments automatically (restart policy)
- Controls how many resources each gets (limits)
- Keeps records of everything (journald logging)

## Unit file structure
Three sections:

[Unit]    → metadata and dependencies
  After=network.target    → start order
  Wants=network-online.target → soft dependency

[Service] → how to run the service
  Type=simple             → main process = ExecStart process
  User=myapp              → run as this user (never root)
  ExecStart=              → exact command to run
  Restart=on-failure      → restart on crash, not on clean exit
  RestartSec=5s           → wait 5s before restart
  StartLimitBurst=3       → give up after 3 crashes in 60s
  MemoryMax=256M          → OOM kill if exceeded
  CPUQuota=50%            → max CPU percentage
  NoNewPrivileges=yes     → cannot escalate to root
  PrivateTmp=yes          → isolated /tmp
  ProtectSystem=strict    → read-only filesystem

[Install] → which boot target
  WantedBy=multi-user.target → start on normal boot

## What is a memory leak?
Program allocates memory but never frees it.
Like a customer taking a shopping trolley and never returning it.
Memory climbs slowly over hours/days until OOM kill.

Healthy app:  memory graph flat (stable)
Memory leak:  memory graph climbing → sawtooth when OOMKilled

Detect:
  watch 'systemctl show myapp --property MemoryCurrent'
  journalctl -u myapp | grep -i "oom\|memory"
  dmesg | grep -i "oom\|killed"

## Why reset-failed is needed
When StartLimitBurst is hit → systemd marks service FAILED and locks it.
systemctl start will fail with "Unit is in failed state".
reset-failed tells systemd: "I fixed it, try again."
Always run reset-failed after fixing a crashed service.

## SyslogIdentifier
Tags all logs with service name instead of program name.
Without it: logs tagged as "python3" — mixed with other python processes.
With it:    logs tagged as "myapp" — filter with journalctl -t myapp

## Break labs completed
Lab A: kill -9 on service → auto-restart in 5 seconds
Lab B: wrong ExecStart → StartLimitBurst → failed state → reset-failed
Lab C: memory leak via /leak endpoint → climbing memory in logs
