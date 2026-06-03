# StatefulSet + Persistent Storage Lab

## What was built
- 2 PVs (pv1, pv2) backed by hostPath on worker-1
- StatefulSet with 2 replicas (web-0, web-1)
- volumeClaimTemplates auto-created data-web-0, data-web-1
- Headless Service for stable DNS per pod

## Key concepts
- volumeClaimTemplates: one PVC per pod, named <template>-<pod>
- Stable identity: deleted web-0 came back as web-0, not a random name
- Data survival: PVC outlives pod, new pod reattaches to same PVC
- reclaimPolicy: Retain means data survives PVC/PV deletion too

## Storage chain
web-0 → data-web-0 → pv1 → /mnt/sre-data/pv1 on worker-1
web-1 → data-web-1 → pv2 → /mnt/sre-data/pv2 on worker-1

## Survival test
kubectl delete pod web-0
# came back as web-0, data intact
