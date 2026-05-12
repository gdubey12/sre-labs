# Day 11 — Full Multi-Service Compose App

## Architecture
Internet → nginx:9999 → flask api:5000
↙           ↘
postgres:5432   redis:6379
(persistent data) (fast cache)
## Key Concepts

### Reverse Proxy (nginx)
- Sits in front of servers — clients never reach Flask directly
- Single entry point: SSL, rate limiting, logging all in one place
- upstream block: defines backend server group — add servers for load balancing
- proxy_set_header: passes real client IP to Flask (X-Real-IP, X-Forwarded-For)
- proxy_connect_timeout / proxy_read_timeout: prevents nginx waiting forever
- access_log off on /health: stops health checks flooding access logs

### Redis vs Postgres — When to Use Which
| | Redis | Postgres |
|---|---|---|
| Speed | Microseconds | Milliseconds |
| Persistence | Lost on restart | Permanent |
| Use for | Counters, cache, sessions | Records, transactions |
| Query | Key lookup only | Full SQL |

### Partial Write Problem
- /visit writes to postgres FIRST then redis
- If redis crashes mid-request: postgres row exists, redis counter not incremented
- Result: data inconsistency between the two stores
- Fix: wrap redis call in try/except — degrade gracefully, don't fail the whole request

### Startup Order
- postgres → redis → api → nginx (enforced via health checks)
- api has retry loop (5 retries, 2s sleep) as additional safety net
- Even with service_healthy, app-level retries are good practice

## Commands Reference
```bash
docker compose up -d                    # start full stack
docker compose ps                       # check health status
docker compose logs api --tail=20       # check api logs
docker compose logs nginx --tail=20     # check nginx access logs
docker stop <container>                 # simulate crash
docker compose up -d <service>          # recover specific service
curl http://localhost:9999/             # test root
curl http://localhost:9999/visit        # write to postgres + redis
curl http://localhost:9999/stats        # read from both stores
```

## Endpoints
| Endpoint | Method | Does |
|---|---|---|
| / | GET | Service status — no DB calls |
| /health | GET | Health check — no DB calls |
| /visit | GET | Write to postgres + increment redis counter |
| /stats | GET | Read redis count + last 5 postgres records |

## Labs Completed
- Built Flask API connecting to both postgres and redis
- Dockerfile with Day 8 best practices (slim, non-root, layer cache)
- nginx reverse proxy with upstream group, headers, timeouts
- Full docker-compose.yml with health checks and startup ordering
- Verified all endpoints end to end
- Break lab: killed redis → 500 on /visit, / still worked
- Observed partial write: postgres row written, redis counter lost
- Recovered: docker compose up -d redis, full stack restored

## Files
- ~/labs/day11/app/app.py
- ~/labs/day11/app/Dockerfile
- ~/labs/day11/app/requirements.txt
- ~/labs/day11/nginx/nginx.conf
- ~/labs/day11/docker-compose.yml
