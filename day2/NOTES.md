# Day 2 — Disk Triage

## Two separate disk limits
df -h → disk SPACE (blocks) — the actual data
df -i → disk INODES — metadata entries, one per file

ALWAYS run both. Space can be fine while inodes are exhausted.
Same error either way: "No space left on device"

## What is an inode?
Every file needs two things:
  1. Disk blocks — the actual data
  2. Inode      — metadata (name, size, owner, permissions)

Library analogy:
  Disk blocks = physical shelf space for books
  Inodes      = index cards in the card catalogue
Run out of index cards = cannot add books even with empty shelves.

## What exhausts inodes in production
  PHP session files never cleaned up
  App creating temp file per request
  Cache system creating file per cache key
  Log rotation creating new file per minute
  High traffic = millions of files = inodes exhausted

Lab result: 1.2M files used all inodes with only 87MB disk space.

## Disk full cascade
Disk 100% → logs fail → DB WAL logs fail → DB stops writes
→ app writes fail → 500 errors → users angry → you get paged
Fix the disk first. Restarting app does nothing.

## Investigation order
1. df -h                                    → which filesystem full?
2. du -sh /* 2>/dev/null | sort -rh | head  → what uses the space?
3. lsof | grep deleted                      → hidden open files?
4. fix → rm or truncate
5. df -h + echo test > /tmp/test            → verify recovery

## The deleted file trick
rm removes the directory entry (the name) NOT the data blocks.
Data blocks freed only when ALL processes close the file.

Detect:
  lsof | grep deleted
  Shows: PROCESS PID USER FD SIZE /path/file (deleted)

Fix without restart (SRE superpower):
  truncate -s 0 /proc/PID/fd/FD_NUMBER
  Space freed instantly, process keeps running, zero downtime

Fix with restart:
  kill -15 PID
  Process closes file, kernel frees blocks

FD number comes from lsof output — the "3w" means fd=3.

## Three disk scenarios

Scenario 1 — Big file on disk:
  df -h shows 100%
  du finds the big file
  rm it → instant recovery

Scenario 2 — Deleted file held open:
  df -h shows 100%
  du shows nothing big (confusing!)
  lsof | grep deleted → finds the held file
  truncate -s 0 /proc/PID/fd/N → freed without restart

Scenario 3 — Inode exhaustion:
  df -h shows FREE SPACE (most confusing!)
  writes still fail with "No space left on device"
  df -i → IUse% at 100%
  find directory with millions of tiny files
  rm -rf directory → inodes recovered instantly

## Key commands
df -h                               # disk space
df -i                               # disk inodes
du -sh /path/* | sort -rh | head    # find space hog
lsof | grep deleted                 # find hidden open files
truncate -s 0 /proc/PID/fd/N       # free space without restart
find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head
                                    # find directory with most files
