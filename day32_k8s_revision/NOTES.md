# Day 32 - Week Review (Days 18-31)

## Gaps to remember

### Control plane flow (kubectl apply)
kubectl → API Server → etcd → Controller Manager → etcd → Scheduler → etcd → kubelet → containerd

Controller Manager creates Pod objects (Pending state)
Scheduler picks the node and writes assignment to etcd
kubelet on that node picks it up and starts the container
etcd is involved at every step - source of truth

### Pending Pod diagnosis checklist
kubectl describe pod <name> → Events section
1. Insufficient resources → reduce requests or add nodes
2. Untolerated taint      → add toleration to Pod
3. Node affinity mismatch → label the node correctly
4. ResourceQuota exceeded → free pods or increase quota
5. PVC not bound          → check PV exists and matches

## Strong areas
- Deployment vs StatefulSet distinction
- OOMKilled cause and fix
- NetworkPolicy default behaviour and CNI requirement
- Secret as env var vs volume mount
- Pending pod diagnosis
