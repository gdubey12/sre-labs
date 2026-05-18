## Day 20 Runbook

### Decode a secret value
kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d

### Rolling update
kubectl set image deployment/<name> <container>=<new-image>
kubectl annotate deployment/<name> kubernetes.io/change-cause="reason"
kubectl rollout status deployment/<name>

### Rollback
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=N

### Pod in ImagePullBackOff
kubectl describe pod <name>    # check Events for exact image pull error

### port-forward to expose service externally for testing
kubectl port-forward service/<name> <localPort>:<servicePort> --address 0.0.0.0
