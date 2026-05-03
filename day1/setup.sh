#!/bin/bash
python3 -c "
import time, os
print(f'Normal app running, PID: {os.getpid()}')
while True:
    time.sleep(1)
" &
echo "Normal app PID: $!"
