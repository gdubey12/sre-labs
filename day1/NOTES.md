# Day 1 — Process Investigation

## What is a process?
A process is a running program. Not the file on disk — the live instance in memory.
Every process has: PID (unique ID), PPID (parent ID), State, Memory, CPU%.

The restaurant analogy:
- Recipe book on shelf = program file on disk (does nothing)
- Actual cooking = the process (live, consuming resources)
- Two pots on stove = two processes from one program

## Process states
R = Running    → actively burning CPU, spinning in user space
S = Sleeping   → waiting for something (network, disk, timer) zero CPU
D = Disk sleep → stuck waiting for IO, kill -9 does nothing
Z = Zombie     → already dead, parent never called wait()

State tells you the problem TYPE before any other investigation:
R → CPU problem | S → waiting problem | D → IO problem | Z → cleanup

## /proc filesystem
Not a real folder — a live window into the kernel brain.
Every process gets /proc/PID/ with these key files:
  status  → Name, State, PPid, VmRSS, Threads
  syscall → what syscall the process is in RIGHT NOW
  stat    → raw CPU ticks: user (own code) vs kernel (syscalls)
  cmdline → exact command that launched this process
  fd/     → every open file descriptor

## Syscalls
User space  = where your code runs (calculations, loops)
Kernel space = where OS runs (controls disk, network, memory)
Syscall = when your program asks the kernel for something real

Key numbers in /proc/PID/syscall:
  "running" → no syscall = pure CPU spin in user space
  45        → recvfrom() = waiting for network data (DB wait)
  35        → nanosleep() = sleeping = healthy
  7         → poll() = server waiting for connections = healthy
  0         → read() = reading from file or socket
  202       → futex() = thread lock = possible deadlock

## CPU ticks (from /proc/PID/stat)
utime = ticks in user space (own code)
stime = ticks in kernel space (syscalls)
High utime, low stime = spin loop (no real work)
Balanced or high stime = legitimate app doing IO

## lsof
lsof -p PID shows everything the process holds open.
No sockets     → rogue script, safe to kill
TCP to port 5432 → waiting on PostgreSQL, fix DB not app

## kill signals
kill -15 (SIGTERM) = polite, process cleans up, always try first
kill -9  (SIGKILL) = force kill, no cleanup, data corruption risk
Always wait 3 seconds after -15 before using -9.

## Zombie fix
Cannot kill zombie — already dead, nothing to kill.
Find parent: PARENT=$(ps -o ppid= -p ZOMBIE_PID | tr -d ' ')
Kill parent:  kill -15 $PARENT
Zombie disappears automatically when parent dies.

## DB wait signature
State S + syscall 45 (recvfrom) + TCP ESTABLISHED to port 5432
= App is healthy. DB is the problem. Fix DB not app.

## 60-second triage
ps aux --sort=-%cpu | head -10   # CPU problem?
free -h                          # Memory problem?
df -h                            # Disk space problem?
df -i                            # Inode problem?
ss -tulnp                        # Network problem?
dmesg | tail -20                 # Kernel events?
