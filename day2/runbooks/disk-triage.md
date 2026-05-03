# Day 2 — Disk Triage Runbook

## DISK FULL
Symptom: "No space left on device" on writes

  df -h                                    # which filesystem?
  du -sh /path/* | sort -rh | head -10     # what is using space?
  lsof | grep deleted                      # hidden open files?
  rm /path/to/bigfile                      # remove culprit
  truncate -s 0 /proc/PID/fd/FD           # free without restart

## INODE EXHAUSTION
Symptom: Writes fail BUT df -h shows free space

ALWAYS run both:
  df -h    # disk space
  df -i    # disk inodes

Find culprit:
  find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -5

Fix:
  rm -rf /directory/with/millions/of/files

Key insight: df -h free ≠ writes will work. Always check df -i.

## DELETED FILE STILL HOLDING SPACE
Symptom: Deleted file, disk still full

Detect:  lsof | grep deleted
Fix:     truncate -s 0 /proc/PID/fd/FD_NUMBER
