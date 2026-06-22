# Day 41 — ArgoCD + GitOps Fundamentals

## Goal

Install ArgoCD, understand its architecture, and prove the core GitOps
reconciliation loop in both directions:

1. Cluster drifts from Git → ArgoCD self-heals it back
2. Git changes → ArgoCD applies it to the cluster automatically

Also demonstrate the difference between **automated** and **manual** sync
policy — the deliberate human checkpoint manual sync introduces.

---

## Why GitOps Differs From Helm

Helm is push-based: you run `helm upgrade` from wherever your kubeconfig is.
GitOps is pull-based: a controller running *inside* the cluster continuously
watches a Git repo and reconciles live state to match it. Git becomes the
single source of truth.

Audit trail comes for free from Git itself — author, commit message, PR
review — rather than just a bare revision number in `helm history`. Rollback
is `git revert` + push (a reviewed, declarative change to desired state)
rather than an imperative `helm rollback` run by hand against the live
cluster.

Caveat worth remembering: `git revert` reverts a whole commit. Bundling
unrelated changes into one commit means reverting undoes all of them —
reinforces the case for small, atomic commits in manifest repos, same as
application code.

---

## ArgoCD Architecture

| Component | Role |
|---|---|
| `argocd-server` | API server — backs UI, CLI, gRPC/REST |
| `argocd-repo-server` | Clones/caches Git repos, renders manifests (plain YAML/Helm/Kustomize) |
| `argocd-application-controller` | The actual reconciliation loop — diffs live state vs. rendered manifests, continuously |
| `argocd-redis` | Caches app state and rendered manifests |
| `argocd-dex-server` | SSO/OIDC bridge (idle here — using local admin auth) |
| `argocd-applicationset-controller` | Templates many Applications from one spec (for scaling to dozens of services) |
| `argocd-notifications-controller` | Alerts on sync/health state changes (Slack, webhook, etc.) |

**Sync status vs. Health status — orthogonal axes:**
- Sync status: does live state match Git? (`Synced` / `OutOfSync`)
- Health status: are resources actually healthy per K8s signals? (`Healthy` / `Progressing` / `Degraded`)

A resource can be `Synced` but `Degraded` (matches Git exactly, but crash-looping) —
the two are tracked independently.

---

## Installation

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd -w
```

7 pods total. One first-boot transient restart on
`argocd-applicationset-controller` self-resolved in ~2s — not a recurring
issue, typical of first-boot leader-election/cert timing.

## Access

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# In its own terminal/MobaXterm tab — must stay running:
kubectl port-forward svc/argocd-server -n argocd 8443:443 --address 0.0.0.0
```

UI: `https://<master-ip>:8443` (self-signed cert warning expected).

CLI install:
```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
argocd login localhost:8443 --username admin --password '<password>' --insecure
```

---

## The Application Object

Created via CLI to make the mapping explicit:

```bash
kubectl create namespace day41-demo

argocd app create day41-nginx \
  --repo https://github.com/gdubey12/sre-labs.git \
  --path day41/manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace day41-demo \
  --sync-policy automated \
  --self-heal
```

Mapping to the `Application` CRD spec:
- `--repo` / `--path` → `spec.source`
- `--dest-*` → `spec.destination`
- `--sync-policy automated --self-heal` → `spec.syncPolicy`

Manifests deployed: a basic nginx `Deployment` (2 replicas) + `ClusterIP`
`Service`, committed under `day41/manifests/` in `sre-labs`.

---

## Proof 1 — Cluster Drift → Self-Heal

```bash
kubectl scale deployment day41-nginx -n day41-demo --replicas=0
kubectl get pods -n day41-demo   # both Terminating
# wait a few seconds
kubectl get pods -n day41-demo   # 2 NEW pods already Running — different pod names
```

New pod names confirmed ArgoCD's controller (not the original pods) reissued
the scale-up within ~1 second of detecting the drift — functionally the same
controller pattern as the ReplicaSet controller, just one layer up, with Git
as the desired-state source instead of the stored Deployment spec.

## Proof 2 — Git Change → Auto-Applied

```bash
sed -i 's/replicas: 2/replicas: 3/' day41/manifests/deployment.yaml
git add day41/manifests/deployment.yaml
git commit -m "Day 41: bump nginx replicas to 3 via GitOps"
git push
# no kubectl command run — just watch:
watch kubectl get pods -n day41-demo
```

Third pod appeared within ~90s on ArgoCD's normal poll cycle. No `kubectl
apply`, no `helm upgrade` — the cluster reacted to a Git commit on its own.

## Proof 3 — Manual Sync Policy (the deliberate checkpoint)

```bash
argocd app set day41-nginx --sync-policy none
sed -i 's/replicas: 3/replicas: 2/' day41/manifests/deployment.yaml
git add day41/manifests/deployment.yaml && git commit -m "revert to 2, testing manual sync" && git push
```

Real-time status check showed a cached/stale read initially (`Synced`
displayed before the controller had actually re-diffed against the new
commit) — `--hard-refresh` and cross-checking the live Deployment's
`spec.replicas` directly gave the trustworthy picture:

```bash
argocd app get day41-nginx --hard-refresh
# Sync Status: OutOfSync from (f539962)
kubectl get deployment day41-nginx -n day41-demo -o jsonpath='{.spec.replicas}'
# 3 — still live, despite Git already saying 2
```

This is the value of manual sync: ArgoCD *detects* drift but won't *act*
without explicit confirmation — exactly the checkpoint production prod
environments often want, contrasted with automated sync for dev/staging.

```bash
argocd app sync day41-nginx   # triggers it manually
kubectl get pods -n day41-demo   # drops to 2, Sync Status back to Synced
```

**Lesson:** don't trust a status panel's cached read over the live cluster
object when the two seem to disagree — `--hard-refresh` or checking the raw
resource spec directly resolves the ambiguity.

---

## Key Commands Summary

```bash
argocd login localhost:8443 --username admin --password '<pw>' --insecure
argocd app create <name> --repo <url> --path <path> --dest-server <server> --dest-namespace <ns> --sync-policy automated --self-heal
argocd app get <name>
argocd app get <name> --hard-refresh
argocd app set <name> --sync-policy none
argocd app sync <name>
```

---

## Incidents / Gotchas

1. Port 8080 already bound on master-1 — used 8443 for port-forward instead.
2. Stale master-1 IP reference (`.157` vs actual static `.21` set via netplan
   back on Days 15–17) — worth keeping a single source of truth for cluster
   IPs going forward.
3. `argocd login` gRPC connection dropped when the port-forward terminal
   session closed — port-forward needs to run in a dedicated, persistent
   tab (MobaXterm tab, not killed by typing elsewhere).
4. `argocd app get` showed a cached `Synced` status briefly before the
   controller had actually re-diffed against a brand-new commit —
   `--hard-refresh` plus checking the live object directly resolved it.

---

## Next: Day 42 onwards — deeper ArgoCD/Flux GitOps (canary, pipeline, projects)
