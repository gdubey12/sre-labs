# Day 36 — Helm Basics: Install, Deploy, Lifecycle

## Core Concepts

| Term | What it is |
|------|-----------|
| **Chart** | A package — a directory of YAML templates + metadata |
| **Release** | A deployed instance of a chart. Same chart, different release = different app instance |
| **Repository** | A remote store of charts (like DockerHub, but for Helm charts) |

### The core value proposition
One `helm install` command → multiple Kubernetes objects created automatically.
One `helm uninstall` command → all of them deleted cleanly.

---

## Installation

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## Chart Repositories

```bash
# Add a repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update local repo cache
helm repo update

# List added repos
helm repo list

# Search for charts in added repos
helm search repo nginx
```

### Chart version vs App version
```
NAME             CHART VERSION   APP VERSION
bitnami/nginx    25.0.2          1.31.1
```
- **Chart version** — version of the Helm packaging
- **App version** — version of the actual application (nginx itself)

---

## Inspecting a Chart Before Installing

```bash
# See all default values you can override
helm show values bitnami/nginx | head -60

# See chart metadata
helm show chart bitnami/nginx

# See full chart info
helm show all bitnami/nginx
```

Always inspect before installing — tells you what values are available to override.

---

## helm install

```bash
helm install my-nginx bitnami/nginx \
  --namespace helm-demo \
  --create-namespace \
  --set service.type=NodePort
```

| Flag | Meaning |
|------|---------|
| `my-nginx` | Release name — your instance name |
| `bitnami/nginx` | Chart to use (repo/chartname) |
| `--namespace helm-demo` | Deploy into this namespace |
| `--create-namespace` | Create namespace if it doesn't exist |
| `--set service.type=NodePort` | Override one value inline |

### What Helm creates (bitnami/nginx example)
From one command, 7 objects were created:
- NetworkPolicy
- PodDisruptionBudget
- ServiceAccount
- Secret (TLS, auto-generated)
- Service (NodePort with your override)
- Deployment (with liveness/readiness probes, resource limits, securityContext)
- ReplicaSet + Pod

All stamped with:
```yaml
app.kubernetes.io/managed-by: Helm
helm.sh/chart: nginx-25.0.2
app.kubernetes.io/instance: my-nginx
```

---

## Checking Releases and Objects

```bash
# List all releases in a namespace
helm list -n helm-demo

# See all Kubernetes objects created by Helm
kubectl get all -n helm-demo

# See the actual rendered manifests Helm sent to Kubernetes
helm get manifest my-nginx -n helm-demo
```

### helm get manifest — key insight
Shows you the final YAML after template rendering. Your `--set` overrides appear here.
The `app.kubernetes.io/managed-by: Helm` label is how Helm tracks what it owns.

---

## helm upgrade

```bash
helm upgrade my-nginx bitnami/nginx \
  --namespace helm-demo \
  --set service.type=NodePort \
  --set replicaCount=2
```

- Increments `REVISION` counter (1 → 2)
- Uses rolling update strategy from the Deployment
- Old pod not killed until new pod is ready
- **Must re-pass all `--set` flags** — upgrade doesn't remember previous flags

---

## helm rollback

```bash
# Roll back to a specific revision
helm rollback my-nginx 1 -n helm-demo
```

### Critical insight — rollback creates a NEW revision
```
REVISION 1 → Install complete      (superseded)
REVISION 2 → Upgrade complete      (superseded)
REVISION 3 → Rollback to 1         (deployed) ← current
```

Helm **never rewrites history**. A rollback is a forward operation applying old config as a new revision. Complete audit trail always preserved.

---

## helm history

```bash
helm history my-nginx -n helm-demo
```

Output:
```
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         deployed    Rollback to 1
```

---

## helm uninstall

```bash
helm uninstall my-nginx -n helm-demo
kubectl delete namespace helm-demo
```

Removes ALL objects Helm created for that release in one command.
Compare: without Helm you'd delete each of the 7 objects manually.

---

## Key Commands Summary

```bash
# Repo management
helm repo add <name> <url>
helm repo update
helm repo list
helm search repo <keyword>

# Inspect
helm show values <chart>
helm show chart <chart>

# Lifecycle
helm install <release> <chart> [flags]
helm upgrade <release> <chart> [flags]
helm rollback <release> <revision> -n <namespace>
helm uninstall <release> -n <namespace>

# Inspect releases
helm list -n <namespace>
helm history <release> -n <namespace>
helm get manifest <release> -n <namespace>
```

---

## Lab: What We Deployed Today

```bash
# Install
helm install my-nginx bitnami/nginx \
  --namespace helm-demo \
  --create-namespace \
  --set service.type=NodePort

# Verify
curl http://192.168.31.158:31722   # nginx welcome page

# Upgrade to 2 replicas
helm upgrade my-nginx bitnami/nginx \
  --namespace helm-demo \
  --set service.type=NodePort \
  --set replicaCount=2

# Rollback to revision 1
helm rollback my-nginx 1 -n helm-demo

# Full history
helm history my-nginx -n helm-demo

# Cleanup
helm uninstall my-nginx -n helm-demo
kubectl delete namespace helm-demo
```

---

## Next: Day 37 — Helm Templating
