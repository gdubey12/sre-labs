## Day 19 — Pods, Deployments, Services

### kubectl commands learned
- `kubectl get pods/nodes/namespaces/service` — list resources
- `kubectl describe pod <name>` — detailed info + events
- `kubectl apply -f <file>` — create or update from YAML
- `kubectl delete pod <name>` — delete a resource
- `kubectl exec -it <pod> -- sh` — shell into a pod
- `kubectl get pods -w` — watch in real time
- `kubectl scale deployment <name> --replicas=N` — scale
- `kubectl rollout status/history deployment <name>` — check releases

### Key observations
- Standalone pod = gone when deleted, nothing brings it back
- Deployment = reconciliation loop replaced deleted pod in 7 seconds
- Service uses label selectors to find pods, not names or IPs
- Pods talk to each other via Service name, CoreDNS resolves it
- ClusterIP = internal only

### Reconciliation loop observed
- Deleted pod manually
- Controller manager detected 2/3 running
- New pod created automatically within 7 seconds
