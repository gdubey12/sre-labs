# Runbook — Multi-Service Compose Stack

## Stack Overview
nginx:9999 → api:5000 → postgres:5432
→ redis:6379

## Starting the Stack
```bash
cd ~/labs/day11
docker compose up -d
docker compose ps          # verify all (healthy)
curl http://localhost:9999/health  # smoke test
```

## Stopping the Stack
```bash
docker compose down          # stop + remove containers, keep volumes
docker compose down -v       # stop + remove containers AND volumes (DESTRUCTIVE)
```

## Checking Health
```bash
docker compose ps                           # overall health status
docker compose logs api --tail=50           # app errors
docker compose logs nginx --tail=50         # access logs, upstream errors
docker compose logs postgres --tail=50      # db errors
docker inspect day11-postgres | grep -A 10 '"Health"'  # detailed health history
```

## Service Down — Diagnosis Flow
```bash
# 1. identify which service is down
docker compose ps

# 2. check its logs
docker compose logs <service> --tail=50

# 3. check if container exists but unhealthy
docker inspect <container> | grep Status

# 4. restart the service
docker compose up -d <service>

# 5. verify recovery
docker compose ps   # wait for (healthy)
curl http://localhost:9999/health
```

## Specific Failure Scenarios

### nginx returns 502 Bad Gateway
- api container is down or unhealthy
- Check: docker compose ps → is day11-api up?
- Check: docker compose logs api
- Fix: docker compose restart api

### /visit returns 500
- redis or postgres is down
- Check: docker compose logs api --tail=20 (look for ConnectionError)
- Redis down: docker compose up -d redis
- Postgres down: docker compose up -d postgres

### api fails to start (DB not ready)
- postgres health check not passing yet
- Check: docker compose logs api → "DB not ready, retrying"
- Wait: postgres needs up to 25s to initialise (5 retries x 5s interval)
- Check postgres: docker compose logs postgres

### Data inconsistency (redis count != postgres rows)
- Caused by partial write — redis crashed mid-request
- Redis count resets on restart — postgres is the source of truth
- To resync: query postgres count and SET redis key manually
```bash
ACTUAL=$(docker exec day11-postgres psql -U sreuser -d srelab -t -c "SELECT COUNT(*) FROM visits;")
docker exec day11-redis redis-cli SET visit_count $ACTUAL
```

## Verifying Data Persistence
```bash
# write some data
curl http://localhost:9999/visit

# destroy and recreate postgres container
docker rm -f day11-postgres
docker compose up -d postgres

# verify data survived
curl http://localhost:9999/stats   # recent_visits should still be there
```

## Nginx Upstream Management
```bash
# check nginx config is valid before applying
docker exec day11-nginx nginx -t

# reload nginx config without downtime
docker exec day11-nginx nginx -s reload
```

## Quick Smoke Test
```bash
curl http://localhost:9999/            # expect: {"status":"ok"}
curl http://localhost:9999/health      # expect: {"status":"healthy"}
curl http://localhost:9999/visit       # expect: {"total_visits": N}
curl http://localhost:9999/stats       # expect: visits from postgres + redis count
```
