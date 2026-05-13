# Runbook: Monitoring Basics

## Scenario: Something broke, where do I look?

### Step 1 — System logs (last 1 hour)
```bash
journalctl --since "1 hour ago"
```
Look for: service crashes, kernel errors, OOM kills

### Step 2 — Filter to specific service
```bash
journalctl -u <service-name> -n 50
```
Common services: ssh, docker, nginx, postgresql

### Step 3 — Container logs
```bash
docker compose logs --since 30m <container>
docker compose logs -f <container>        # follow live
```
Look for: 500 errors, exceptions, slow response warnings

### Step 4 — Live resource usage
```bash
docker stats
```
Look for: CPU spike, memory growing, NET I/O counter climbing fast

## Boot boundary
```bash
journalctl -u <service> | grep -A2 "Boot"
```
Did the issue start before or after last restart?

## Docker network debug
```bash
docker network ls                          # list all networks
docker network inspect <network-name>      # show subnet, gateway, containers
ip addr | grep 172                         # find bridge interfaces on host
```
