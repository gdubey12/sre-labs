# Day 8 — Dockerfile Best Practices

## IMAGE SIZE
Use slim base images:
  python:3.11        → 1.62GB  avoid
  python:3.11-slim   → 210MB   use this
  python:3.11-alpine → ~50MB   use for smallest (compatibility issues sometimes)

## LAYER CACHING
Copy dependencies BEFORE application code:
  COPY requirements.txt .          # changes rarely
  RUN pip install -r requirements.txt  # cached unless requirements change
  COPY app.py .                    # changes frequently

Wrong order = pip reinstalls on every code change (slow builds)
Correct order = pip cached unless requirements.txt changes

## PIP FLAGS
RUN pip install --no-cache-dir -r requirements.txt
  --no-cache-dir  → don't store pip cache in image (smaller image)

## NON-ROOT USER
RUN useradd --system --no-create-home --shell /usr/sbin/nologin appuser
RUN chown -R appuser:appuser /app
USER appuser

Never run containers as root. If compromised:
  root    → attacker has full container control, can escape to host
  appuser → attacker has limited access, cannot escalate

## .DOCKERIGNORE
Always create .dockerignore:
  .git          → exclude git history (can be MBs)
  .env          → NEVER put secrets in image
  *.pyc         → unnecessary compiled files
  __pycache__   → Python cache directory
  *.log         → log files don't belong in image

## CMD FORMAT
Correct:   CMD ["python3", "app.py"]   → PID 1 = python3, SIGTERM works
Wrong:     CMD python3 app.py          → PID 1 = shell, SIGTERM ignored

## PIN BASE IMAGE DIGEST
# Get digest:
docker inspect IMAGE | grep RepoDigests

# Use in Dockerfile:
FROM python:3.11-slim@sha256:DIGEST_HERE

Tag can change → different image tomorrow
Digest never changes → reproducible builds forever

## CVE SCANNING
trivy image IMAGE                              # scan all severities
trivy image --severity HIGH,CRITICAL IMAGE     # only serious ones

CRITICAL → fix immediately, block deployment
HIGH     → fix within 48 hours
MEDIUM   → fix within sprint
LOW      → track, fix when convenient

## CHECKLIST FOR EVERY DOCKERFILE
[ ] Using slim or alpine base image?
[ ] Requirements copied before application code?
[ ] --no-cache-dir in pip install?
[ ] .dockerignore exists?
[ ] Running as non-root user?
[ ] CMD uses array format?
[ ] Base image pinned to digest?
[ ] Trivy scan passes with no CRITICAL?

## MULTI-STAGE BUILDS
Use when: compiled languages (Go, Java, Node) or when build tools
          should not exist in production image

Pattern:
  Stage 1 (builder):
    FROM python:3.11-slim AS builder
    RUN apt-get install gcc    ← build tools here
    RUN pip install --prefix=/install -r requirements.txt

  Stage 2 (runtime):
    FROM python:3.11-slim AS runtime
    COPY --from=builder /install /usr/local  ← only packages, no gcc
    USER appuser

--prefix=/install → installs packages into isolated directory
                    so only packages are copied, not build tools
COPY --from=builder → copies from previous stage, not host

Benefits:
  Build tools never reach production
  Source code can be excluded from final image
  Smaller attack surface
  For Go/Java: 800MB → 8MB possible
