# Day 6 — Docker Runbook

## KEY COMMANDS
docker ps                    # running containers
docker ps -a                 # all containers including stopped
docker images                # available images
docker run -d -p H:C --name N IMAGE  # run container
docker exec -it NAME bash    # shell inside container
docker logs NAME             # output from container
docker stop NAME             # graceful stop (SIGTERM)
docker rm NAME               # remove stopped container
docker rmi IMAGE             # remove image
docker build -t NAME:TAG .   # build image from Dockerfile

## RUN FLAGS
-d          → detached (background)
-it         → interactive terminal
-p H:C      → port mapping host:container
-v H:C      → volume mount host:container
--name      → give container a name
--rm        → remove container when it exits

## DOCKERFILE INSTRUCTIONS
FROM        → base image
WORKDIR     → set working directory
COPY        → copy files from host into image
RUN         → execute command during build
EXPOSE      → document which port app listens on
CMD         → command to run when container starts
ENV         → set environment variables

## DEBUGGING
Container not running:
  docker ps -a               → check STATUS and EXIT CODE
  docker logs NAME           → read crash output

Exit codes:
  0   = clean exit
  1   = application error
  137 = OOMKilled
  143 = SIGTERM (graceful stop)

## VOLUMES
Without volume: data lost when container removed
With volume:    data persists on host

docker run -v /host/path:/container/path IMAGE

Production pattern:
  Code/app    → baked into image (rebuild for changes)
  Config      → volume mount (change without rebuild)
  Data/logs   → volume mount (persist across restarts)

## COMMON ERRORS
"Unable to find image" → wrong tag, check docker images
"port already allocated" → use different host port
"Exited (1)" → app crashed, check docker logs
"permission denied" → run with sudo or fix user permissions
