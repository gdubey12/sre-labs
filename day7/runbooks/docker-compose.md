# Day 7 — Docker Networking and Compose Runbook

## DOCKER COMPOSE COMMANDS
docker compose up -d              # start all services
docker compose down               # stop and remove all
docker compose ps                 # check status
docker compose logs SERVICE       # view logs
docker compose logs -f SERVICE    # follow logs live
docker compose restart SERVICE    # restart one service
docker compose up -d --build SERVICE  # rebuild and restart

## NETWORKING
Compose auto-creates: FOLDER_default network
Containers reach each other by SERVICE NAME (not IP)
DNS resolution: "api" → container IP automatically

## DEBUGGING 502 BAD GATEWAY
Step 1: docker logs sre-nginx | tail -10
        Read the error code:
        111 = Connection refused  → wrong port or service down
        113 = Host unreachable    → network disconnection

Step 2: docker compose ps
        Is the upstream container running?

Step 3: docker inspect CONTAINER | grep -A5 Networks
        Is it connected to the right network?
        Empty Networks = disconnected

Step 4: docker exec CONTAINER env | grep PORT
        Is it using the right port?

## COMMON ERRORS AND FIXES
502 + "Host unreachable":
  Cause: container disconnected from network
  Fix:   docker network connect NETWORK CONTAINER

502 + "Connection refused":
  Cause: container on network but wrong port
  Fix:   correct environment variable, recreate container

Container exits immediately:
  Check: docker logs CONTAINER
  Fix:   based on error message

## DOCKER NETWORKS
docker network ls                          # list networks
docker network inspect NETWORK            # see connected containers
docker network connect NETWORK CONTAINER  # add container to network
docker network disconnect NETWORK CONTAINER # remove from network

## KEY CONCEPTS
depends_on    → start order (not readiness check)
restart: unless-stopped → restart on crash, not on manual stop
environment   → set env vars (PORT, DB_URL, etc)
volumes       → mount host files into container
ports         → expose container port to host
