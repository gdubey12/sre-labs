## Day 19 Runbook — Pods, Deployments, Services

### Pod is stuck in Pending
kubectl describe pod <name>
Look at Events — usually one of:
- No nodes available with enough CPU/memory
- PVC not bound (storage issue)
- Image pull waiting

### Pod is in CrashLoopBackOff
kubectl logs <pod-name>
kubectl logs <pod-name> --previous   # logs from crashed container
kubectl describe pod <pod-name>      # check Events section
### Pod is stuck in Terminating
kubectl delete pod <name> --force --grace-period=0

### Check what's running in a namespace
kubectl get all -n <namespace>

### Service not routing traffic
Verify selector matches pod labels
kubectl describe service <name>
kubectl get pods --show-labels
Test from inside cluster
kubectl run test --image=busybox --rm -it --restart=Never -- wget -qO- <service-name>

### Scale a Deployment
kubectl scale deployment <name> --replicas=N

### Rollback a Deployment
kubectl rollout history deployment <name>
kubectl rollout undo deployment <name>
kubectl rollout undo deployment <name> --to-revision=<N>

### Get shell inside a running pod
kubectl exec -it <pod-name> -- sh
