# Day 29 - Resource Limits, LimitRange, ResourceQuota

## Three layers of resource control

requests/limits  → per container declaration (scheduler + kubelet use this)
LimitRange       → per namespace, per container guardrails + defaults
ResourceQuota    → per namespace total budget ceiling

## requests vs limits

- requests: scheduler uses this to pick a node (guaranteed minimum)
- limits:   kubelet enforces this at runtime
  - CPU hit  → throttled (slowed, not killed)
  - Memory hit → OOMKilled (container dies)

## QoS Classes (automatic)

- Guaranteed  → requests == limits. Last evicted.
- Burstable   → requests set, limits higher. Middle.
- BestEffort  → nothing declared. First evicted.

## LimitRange

- Applies at Pod CREATION time only
- Does NOT affect already-running Pods
- Four fields:
  - min          → container cannot declare below this
  - max          → container cannot declare above this
  - defaultRequest → injected if container declares nothing
  - default        → injected if container declares nothing

## ResourceQuota

- Watches namespace TOTAL, not individual containers
- Counts pods regardless of whether requests/limits declared
- But only counts cpu/memory if requests/limits are declared
- Rejects at admission when ceiling hit

## Why both together

- ResourceQuota alone → Pod with no resources gets rejected (nothing to count)
- LimitRange alone    → no total budget, one team can eat everything
- Together            → LimitRange injects defaults so ResourceQuota always
                        has something to count

## Key commands

kubectl get limitrange --all-namespaces
kubectl get resourcequota --all-namespaces
kubectl describe limitrange <name> -n <ns>
kubectl describe resourcequota <name> -n <ns>
kubectl describe nodes | grep -A 8 "Allocated resources"

## Lab files

- no-resources-pod.yaml   → BestEffort pod, no declarations
- limitrange.yaml         → dev-limits with min/max/default
- resourcequota.yaml      → dev-quota with pod + cpu + memory caps
- auto-limits-pod.yaml    → pod with defaults injected by LimitRange
- bust-quota-pod.yaml     → proved quota rejection at admission

## Observed

- no-resources-pod: blank Limits/Requests (created before LimitRange)
- auto-limits-pod:  100m/128Mi requests, 500m/256Mi limits (injected)
- bust-pod-2: forbidden - exceeded quota (pods=3/3, limits.cpu=1/1)
