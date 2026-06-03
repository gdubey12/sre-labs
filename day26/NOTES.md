## Day 26 — Ingress: Path-based and Host-based Routing

### Cluster setup
- Hard-way cluster — no Traefik, no MetalLB
- Installed nginx-ingress controller (baremetal manifest)
- Controller runs on worker-1 (192.168.31.158)
- NodePort: HTTP=30556, HTTPS=31218
- Deleted admission webhook (caused i/o timeout on hard-way cluster)

### Key concepts
Ingress = two pieces:
  1. Ingress Controller  — the actual pod handling traffic (nginx)
  2. Ingress Resource    — your YAML defining routing rules

### Traffic flow
curl → worker-1:30556 → nginx-ingress controller → Service (ClusterIP) → Pod

### Path-based routing
- Same hostname, path decides backend
- rewrite-target: / needed for dumb backends (http-echo)
- Without rewrite: backend receives /app1 → 404

### Host-based routing
- Different hostnames, same IP
- Controller reads Host: header in HTTP request
- No rewrite needed (path is just /)

### Why not port 80?
- NodePort range is 30000-32767
- Port 80 needs MetalLB or HAProxy in front
- Production: LB → port 80 → ingress controller → app

### /etc/hosts entries added
192.168.31.158 myapp.local
192.168.31.158 app1.local
192.168.31.158 app2.local

### Files
- apps.yaml          — two http-echo deployments + services
- ingress-path.yaml  — path-based ingress (myapp.local/app1, /app2)
- ingress-host.yaml  — host-based ingress (app1.local, app2.local)
