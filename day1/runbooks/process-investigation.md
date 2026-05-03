# Day 1 — Process Investigation Runbook

## CPU HOG
Symptom: System slow, load average high

Step 1 - Find it:
  ps aux --sort=-%cpu | head -10

Step 2 - Check state:
  cat /proc/PID/status | grep -E "Name|State|PPid|VmRSS"
  R = spinning, S = waiting, Z = zombie, D = stuck on disk

Step 3 - Catch in the act:
  cat /proc/PID/syscall
  "running" = spin loop in user space
  45 = recvfrom (waiting on network)

Step 4 - Check connections:
  lsof -p PID
  No sockets = rogue script, kill it
  TCP to DB = app waiting on DB, fix DB not app

Step 5 - Kill safely:
  kill -15 PID    (wait 3s)
  kill -9 PID     (only if -15 fails)

## ZOMBIE PROCESS
Symptom: State Z in ps, kill -9 does nothing

Why: Process already dead, parent never called wait()
Fix: kill -15 PARENT_PID
Find parent: ps -o ppid= -p ZOMBIE_PID

## DB WAIT
Symptom: App slow, CPU near zero, State S

Signature: State S + syscall 45 + TCP to port 5432
Means: App healthy, DB is the problem
Action: Fix DB query, NOT restart app

## 60-SECOND TRIAGE
  ps aux --sort=-%cpu | head -10   # CPU
  free -h                          # Memory
  df -h                            # Disk space
  df -i                            # Disk inodes
  ss -tulnp                        # Network
  dmesg | tail -20                 # Kernel events
