#!/bin/bash
echo "[BREAK] Filling /home disk with a large file..."
dd if=/dev/zero of=/home/coolboy/BIGFILE bs=1M count=15000 &
DD_PID=$!
echo "[BREAK] Fill process PID: $DD_PID"

echo "[BREAK] Starting log spammer..."
mkdir -p /home/coolboy/fakelogs
while true; do
    echo "$(date) ERROR something terrible happened in service X pid=$$" >> /home/coolboy/fakelogs/app.log
    sleep 0.1
done &
LOG_PID=$!
echo "[BREAK] Log spammer PID: $LOG_PID"
echo "[BREAK] Watch df -h /home in Tab 2"
