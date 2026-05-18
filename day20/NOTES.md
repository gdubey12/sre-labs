## Day 20 — ConfigMaps, Secrets, NodePort, Rolling Updates

### ConfigMap
- Decouples config from container image
- Injected as env vars or volume mounts
- kubectl describe shows values in plain text — not for sensitive data

### Secret
- Same as ConfigMap but base64 encoded
- kubectl describe hides values
- Never commit real secrets to git

### Service types
- ClusterIP — internal only, pod-to-pod
- NodePort — exposes on node IP + fixed port (30000-32767)
- LoadBalancer — cloud provider LB in front (Day 50+)
- ExternalName — maps to external DNS (Day 26-27 with Ingress)

### port-forward vs NodePort
- port-forward — development tunnel, dies when Ctrl+C
- NodePort — always on, native node routing

### Rolling update
- New pod healthy first, then old pod killed — zero downtime
- Each update creates a new ReplicaSet
- kubectl set image deployment/<name> <container>=<new-image>

### Rollback
- Old ReplicaSets kept around specifically for rollback
- Rollback reuses old ReplicaSet, creates new revision
- kubectl rollout undo deployment/<name>
- kubectl rollout undo deployment/<name> --to-revision=N

### Annotation tip
- Annotate before or at time of change, not after
- Annotation sticks to Deployment object, not specific revision
