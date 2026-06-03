# Project 1 — Stateful Guestbook App

## Components
- Namespace: guestbook
- Frontend: nginx Deployment + NodePort Service (port 30080)
- Backend: busybox StatefulSet (2 replicas) + Headless Service
- Storage: 2 PVs (hostPath) + volumeClaimTemplates (auto PVC per pod)
- ConfigMap: nginx.conf + index.html for frontend
- RBAC: backend-sa ServiceAccount + Role (get/list/watch pods,configmaps) + RoleBinding
- NetworkPolicy: deny-all + allow-external-to-frontend + allow-frontend-to-backend

## Tests passed
1. curl http://192.168.31.158:30080 → HTML from ConfigMap
2. curl http://192.168.31.158:30080/entries/log.txt → data from backend PVC
3. test-pod direct to backend → blocked by NetworkPolicy (wget timed out)

## Key lessons
- deny-all must be paired with explicit allow policies including external traffic
- volumeClaimTemplates auto-creates PVCs per pod (data-backend-0, data-backend-1)
- Downward API should be used instead of hostname for pod identity
- ServiceAccount per workload = least privilege + auditability
