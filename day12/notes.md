# Day 12 — CI/CD Pipeline Advanced

**Date:** 2026-05-12
**Repo:** github.com/gdubey12/sre-cicd-app
**Branch work:** feature/day12-matrix-cache, feature/day12-notifications, feature/break-lab-notification

---

## What I Learned

### Matrix Builds
- `strategy.matrix` in a job spins up parallel runners, one per value
- All 3 Python versions (3.10, 3.11, 3.12) ran simultaneously — not sequentially
- If one version fails, GitHub reports it immediately without waiting for others
- Downstream jobs (`build`, `security-scan`) only start after ALL matrix jobs pass

### Pip Caching
- `actions/cache@v4` caches `~/.cache/pip` between runs
- Cache key = `OS + python-version + hash(requirements.txt)`
- If `requirements.txt` changes → cache key changes → fresh install
- If nothing changes → pip restores from cache → faster builds

### Matrix + PR Protection Rules Problem
- Before matrix: one job called `Run Tests` reported status
- After matrix: jobs are named `Run Tests (3.10)`, `Run Tests (3.11)`, `Run Tests (3.12)`
- Old required check `Run Tests` never gets reported → PR stuck forever
- Fix: add a `tests-complete` summary job that `needs: test` → update ruleset to require `tests-complete`

### tests-complete Summary Job
- A lightweight job (just `echo`) that runs after all matrix jobs
- Reports a single stable check name regardless of how many matrix versions exist
- Production-grade pattern used by real teams

### Failure Notifications
- `if: failure()` — job only runs if any upstream job in `needs:` failed
- `if: success()` — runs only on success (default behaviour)
- Sends JSON payload via curl to webhook endpoint
- Payload includes: status, repo, branch, commit SHA, direct run URL
- In production: replace webhook.site with Slack webhook or PagerDuty

### github.sha
- Every commit gets a unique SHA (hash)
- Docker images tagged with SHA = full traceability
- Can always rollback to exact image that ran before
- `latest` tag is just a floating pointer — not safe for rollback

---

## Pipeline Architecture (Final)

```
Matrix: Run Tests (3.10, 3.11, 3.12)
    ├──→ tests-complete (PR gate)
    └──→ Build Docker Image
              └──→ Security Scan (Trivy)
                        └──→ Push to DockerHub (main only)

[any failure] → Notify on Failure → webhook/Slack
```

---

## Commands Used

```bash
# Clone repo fresh for day12
git clone https://github.com/gdubey12/sre-cicd-app day12/sre-cicd-app

# Feature branch workflow
git checkout -b feature/day12-matrix-cache
git add .github/workflows/ci.yml
git commit -m "day12: add matrix builds and pip caching"
git push origin feature/day12-matrix-cache

# Pull image and verify
docker pull gaurav0524/sre-cicd-app:latest
docker run --rm -p 5000:5000 gaurav0524/sre-cicd-app:latest
curl http://localhost:5000/health
```

---

## Key Concepts

| Concept | Explanation |
|---|---|
| Matrix build | Run same job with different inputs in parallel |
| Cache key | Unique identifier — cache only reused if key matches |
| hashFiles() | GitHub expression — returns hash of file contents |
| if: failure() | Conditional — job runs only when upstream failed |
| github.sha | Unique commit hash — used to tag Docker images |
| tests-complete | Summary job — stable PR gate for matrix pipelines |
