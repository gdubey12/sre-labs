#!/bin/bash
python3 -c "
import os, time
print(f'[HOG] started, PID={os.getpid()} — find me without this PID')
while True:
    pass
" &
echo "[BREAK DONE] — now investigate from Tab 1. Glance at Tab 2."
