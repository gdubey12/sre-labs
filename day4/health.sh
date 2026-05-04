#!/bin/bash
# SRE Health Check Script
# Usage: bash health.sh

# Colors for output
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
NC='\033[0m'  # No color

# Thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=80
INODE_THRESHOLD=80

# Status tracking
STATUS="OK"
ISSUES=()

# Helper functions
log()   { echo "[$(date '+%H:%M:%S')] $1"; }
ok()    { echo -e "${GRN}[OK]${NC}    $1"; }
warn()  { echo -e "${YEL}[WARN]${NC}  $1"; STATUS="DEGRADED"; ISSUES+=("$1"); }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; STATUS="CRITICAL"; ISSUES+=("$1"); }

echo "=================================="
echo " SRE Health Check — $(hostname)"
echo " $(date)"
echo "=================================="
echo ""

# ─── CPU CHECK ───────────────────────────────────────────
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)

if [ "$CPU" -gt "$CPU_THRESHOLD" ]; then
    fail "CPU HIGH: ${CPU}% (threshold ${CPU_THRESHOLD}%)"
elif [ "$CPU" -gt $((CPU_THRESHOLD - 10)) ]; then
    warn "CPU WARNING: ${CPU}% (threshold ${CPU_THRESHOLD}%)"
else
    ok "CPU: ${CPU}%"
fi

# ─── MEMORY CHECK ────────────────────────────────────────
MEM_TOTAL=$(free | awk '/^Mem:/{print $2}')
MEM_USED=$(free | awk '/^Mem:/{print $3}')
MEM_PCT=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED/$MEM_TOTAL)*100}")
MEM_AVAIL=$(free -h | awk '/^Mem:/{print $7}')

if [ "$MEM_PCT" -gt "$MEM_THRESHOLD" ]; then
    fail "MEMORY HIGH: ${MEM_PCT}% used (${MEM_AVAIL} available)"
elif [ "$MEM_PCT" -gt $((MEM_THRESHOLD - 10)) ]; then
    warn "MEMORY WARNING: ${MEM_PCT}% used (${MEM_AVAIL} available)"
else
    ok "Memory: ${MEM_PCT}% used (${MEM_AVAIL} available)"
fi

# ─── DISK SPACE CHECK ────────────────────────────────────
echo ""
while IFS= read -r line; do
    USE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    AVAIL=$(echo "$line" | awk '{print $4}')

    if [ "$USE" -gt "$DISK_THRESHOLD" ]; then
        fail "DISK FULL: $MOUNT at ${USE}% (${AVAIL} free)"
    elif [ "$USE" -gt $((DISK_THRESHOLD - 10)) ]; then
        warn "DISK WARNING: $MOUNT at ${USE}% (${AVAIL} free)"
    else
        ok "Disk $MOUNT: ${USE}% used (${AVAIL} free)"
    fi
done < <(df -h | tail -n +2 | grep -v tmpfs | grep -v udev)

# ─── INODE CHECK ─────────────────────────────────────────
while IFS= read -r line; do
    USE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')

    [ -z "$USE" ] || [ "$USE" = "-" ] && continue

    if [ "$USE" -gt "$INODE_THRESHOLD" ]; then
        fail "INODES EXHAUSTED: $MOUNT at ${USE}%"
    elif [ "$USE" -gt $((INODE_THRESHOLD - 10)) ]; then
        warn "INODES WARNING: $MOUNT at ${USE}%"
    else
        ok "Inodes $MOUNT: ${USE}% used"
    fi
done < <(df -i | tail -n +2 | grep -v tmpfs | grep -v udev)

# ─── SERVICE WATCHDOG ────────────────────────────────────
echo ""
check_service() {
    local NAME=$1
    local PORT=$2

    if systemctl is-active --quiet "$NAME" 2>/dev/null; then
        ok "Service $NAME: running"
    elif nc -z -w2 localhost "$PORT" 2>/dev/null; then
        ok "Service $NAME: responding on port $PORT"
    else
        fail "Service $NAME: DOWN on port $PORT"
        # Auto-restart if systemd manages it
        if systemctl list-units --full -all 2>/dev/null | grep -q "$NAME"; then
            log "Attempting restart of $NAME..."
            sudo systemctl restart "$NAME" 2>/dev/null && \
                log "$NAME restarted successfully" || \
                log "$NAME restart failed"
        fi
    fi
}

# Add services to monitor here
check_service "ssh" "22"
check_service "docker" "2375"

# ─── LOG ERROR SCANNER ───────────────────────────────────
echo ""
check_logs() {
    local LOGFILE=$1
    local THRESHOLD=${2:-10}

    if [ ! -f "$LOGFILE" ]; then
        ok "Log $LOGFILE: not found (skipping)"
        return
    fi

    # Count errors in last 100 lines
    ERROR_COUNT=$(tail -100 "$LOGFILE" 2>/dev/null | \
        grep -c -iE "error|fatal|critical|failed" 2>/dev/null | tr -d "\n" || echo 0)

    if [ "$ERROR_COUNT" -gt "$THRESHOLD" ]; then
        fail "LOG ERRORS: $LOGFILE has ${ERROR_COUNT} errors in last 100 lines"
        tail -3 "$LOGFILE" | grep -iE "error|fatal" | while read -r line; do
            echo "         → $line"
        done
    elif [ "$ERROR_COUNT" -gt 0 ]; then
        warn "LOG WARNINGS: $LOGFILE has ${ERROR_COUNT} errors in last 100 lines"
    else
        ok "Log $LOGFILE: no errors"
    fi
}

check_logs "/var/log/syslog"
check_logs "/home/coolboy/fakelogs/app.log"

# ─── SUMMARY ─────────────────────────────────────────────
echo ""
echo "=================================="
if [ "$STATUS" = "OK" ]; then
    echo -e "${GRN}Overall: HEALTHY${NC}"
elif [ "$STATUS" = "DEGRADED" ]; then
    echo -e "${YEL}Overall: DEGRADED${NC}"
else
    echo -e "${RED}Overall: CRITICAL${NC}"
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo ""
    echo "Issues found:"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
fi
echo "=================================="

# ─── SLACK ALERT ─────────────────────────────────────────
SLACK_WEBHOOK=""  # paste your webhook URL here

send_slack() {
    local MSG=$1
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"*[$(hostname)]* $MSG\"}" \
            "$SLACK_WEBHOOK" > /dev/null
        log "Slack alert sent"
    fi
}

if [ "$STATUS" != "OK" ]; then
    ISSUE_LIST=$(printf ' | %s' "${ISSUES[@]}")
    send_slack "ALERT ${STATUS}: ${ISSUE_LIST:3}"
fi
