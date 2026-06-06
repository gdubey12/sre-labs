# Day 31 - Project 2: Multi-tier App with Resource Governance and Scheduling Control

## What was built

Namespace: project2
- LimitRange: default requests/limits injected for all containers
- ResourceQuota: cpu, memory, pod count ceiling

Components:
- frontend Deployment (nginx, 2 replicas) + ClusterIP Service port 80
- backend Deployment (busybox, 1 replica) + ClusterIP Service port 8080
- ConfigMap: app-config (APP_ENV, LOG_LEVEL)
- Secret: app-secret (DB_PASSWORD)
- PV: pv0 (1Gi, hostPath, Retain)
- PVC: pvc0 (500Mi, Bound to pv0)

## Scheduling design

worker-1 tainted: tier=backend:NoSchedule
worker-1 labelled: tier=backend

frontend: no toleration → stays Pending (proved taint works)
backend:  toleration for tier=backend + nodeAffinity required tier=backend → Running

## Key lessons

1. Tab vs spaces in yaml — always use spaces. Tabs cause parse errors.
2. Two envFrom sources (ConfigMap + Secret) go in one envFrom block as a list.
3. volumes: goes at Pod spec level, not inside containers:
4. Test pods also need tolerations if node is tainted
5. Connection refused on busybox service is expected — nothing listening on 8080
6. PVC write test: echo test > /data/test.txt proved mount working

## Key commands used

kubectl taint nodes worker-1 tier=backend:NoSchedule
kubectl label node worker-1 tier=backend
kubectl expose deployment backend --port=8080 --target-port=8080 -n project2
kubectl exec -n project2 deploy/backend -- sh -c "echo test > /data/test.txt && cat /data/test.txt"
kubectl logs -n project2 deploy/backend
kubectl describe resourcequota -n project2

## Files

frontend.yaml     - Deployment + Service
backend.yaml      - Deployment with toleration, affinity, envFrom, volumeMount
pv.yaml           - PV + PVC
configmap.yaml    - app-config
secret.yaml       - app-secret
