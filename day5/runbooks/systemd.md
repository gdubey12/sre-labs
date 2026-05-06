# Day 5 — Systemd Runbook

## KEY COMMANDS
systemctl status myapp              # is it running? last events?
systemctl start/stop/restart myapp  # control the service
systemctl enable/disable myapp      # autostart on boot or not
systemctl daemon-reload             # after editing .service file
systemctl reset-failed myapp        # clear failed state before restart
journalctl -fu myapp                # follow logs live
journalctl -u myapp -n 50          # last 50 lines
journalctl -u myapp --since today  # today's logs only
journalctl -u myapp -p err         # only errors
systemctl show myapp | grep Memory # check memory usage

## UNIT FILE SECTIONS
[Unit]    = description, dependencies, start order
[Service] = how to run, restart policy, resource limits, security
[Install] = which boot target to attach to

## RESTART POLICY
Restart=no           → never restart
Restart=always       → always restart
Restart=on-failure   → restart only on crash (recommended)
RestartSec=5s        → wait 5s before restarting
StartLimitBurst=3    → give up after 3 failures in StartLimitInterval
StartLimitInterval=60s

## RESOURCE LIMITS
MemoryMax=256M   → OOM kill if exceeded
CPUQuota=50%     → max 50% of one CPU core
LimitNOFILE=65536 → max open file descriptors

## SECURITY
NoNewPrivileges=yes  → cannot escalate to root
PrivateTmp=yes       → isolated /tmp directory
ProtectSystem=strict → filesystem read-only except ReadWritePaths
User=myapp           → run as dedicated system user, not root

## BREAK/FIX SCENARIOS

Scenario 1: Service crashes — auto-restart
  Symptom: service restarts every few minutes
  Check:   journalctl -u myapp | grep "Main process exited"
  Read:    exit code — 0=clean, 1=error, 9=killed, 137=OOMKill

Scenario 2: Service in failed state — won't start
  Symptom: systemctl start myapp → "Unit is in failed state"
  Cause:   StartLimitBurst hit — crashed too many times
  Fix:     systemctl reset-failed myapp → then start again

Scenario 3: Wrong ExecStart path
  Symptom: starts then immediately exits, status=2/INVALIDARGUMENT
  Check:   journalctl -u myapp -n 5 → "No such file or directory"
  Fix:     correct path in unit file → daemon-reload → start

Scenario 4: Memory leak
  Symptom: memory climbing in systemctl status, eventual OOMKill
  Detect:  watch 'systemctl show myapp --property MemoryCurrent'
  Confirm: journalctl -u myapp | grep -i "oom\|killed\|memory"
  Fix:     restart service (temporary) → fix leak in code (permanent)

## FULL RECOVERY WORKFLOW
1. systemctl status myapp          → read the error
2. journalctl -u myapp -n 30      → read logs for root cause
3. fix the problem (unit file or app code)
4. systemctl daemon-reload         → if unit file changed
5. systemctl reset-failed myapp   → if in failed state
6. systemctl start myapp           → start it
7. systemctl status myapp          → verify running
