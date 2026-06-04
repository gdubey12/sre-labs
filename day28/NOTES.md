## Day 28 — RBAC Lab

### Core objects
Role            → permissions in one namespace
ClusterRole     → permissions across all namespaces
RoleBinding     → connects Role/ClusterRole to subject in one namespace
ClusterRoleBinding → connects ClusterRole to subject cluster-wide

### Subject types
User            → identity from certificate CN field
Group           → identity from certificate O field
ServiceAccount  → K8s object, used for pod identity

### Scenario 1 — Developer (gauri)
- CN=gauri (no O= group to avoid inheriting group bindings)
- Role: pod-reader (get/list/watch pods, pods/log)
- RoleBinding: gauri-pod-reader in dev namespace
- Cannot delete, cannot access prod

### Scenario 2 — CI/CD ServiceAccount (cicd-sa)
- ServiceAccount in dev namespace
- Role: deployment-manager (get/list/update/patch deployments)
- RoleBinding: cicd-binding in dev namespace
- Test with: --as=system:serviceaccount:dev:cicd-sa
- Cannot delete, cannot access prod

### Scenario 3 — Auditor
- CN=auditor
- ClusterRole: cluster-auditor (get/list/watch pods/services/deployments/ingresses/networkpolicies/secrets)
- ClusterRoleBinding: auditor-binding (cluster-wide)
- Can read across ALL namespaces
- Cannot modify anything

### Key commands
kubectl auth can-i list pods -n dev --as=gauri
kubectl auth can-i --list -n dev --as=gauri
kubectl auth can-i list deployments -n dev --as=system:serviceaccount:dev:cicd-sa
kubectl get rolebindings -n dev
kubectl get clusterrolebindings | grep auditor

### Important lessons
- "No resources found" ≠ "Forbidden" — check the error message
- User cert O= field = group membership — be careful
- ClusterRole + RoleBinding = namespace scoped (not cluster-wide)
- ClusterRole + ClusterRoleBinding = truly cluster-wide
