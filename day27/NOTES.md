## Day 27 — Ingress Deep Dive

### Key learnings

#### Ingress + NetworkPolicy interaction
- Ingress controller lives in ingress-nginx namespace
- Traffic to backend pod comes FROM ingress-nginx namespace
- NetworkPolicy must explicitly allow ingress-nginx namespace
- Symptom of missing rule: 504 Gateway Timeout (not 403)
- Debug flow: curl → check pod → check svc → check NetworkPolicy

#### Default Backend
- Catchall for unmatched rules
- Must be in same namespace as the Ingress resource
- Without it: nginx returns generic 404
- With it: your custom response

#### Namespace rule
- Ingress and its backend Service must be in same namespace
- Ingress resource location ≠ where traffic comes from
- Traffic always comes from ingress-nginx controller pod

### Ingress debug checklist
1. kubectl get ingress -n <namespace>        # rule exists?
2. kubectl describe ingress -n <namespace>   # backend correct?
3. kubectl get svc -n <namespace>            # service exists?
4. kubectl exec pod -- wget localhost        # pod serving traffic?
5. kubectl get networkpolicy -n <namespace>  # anything blocking?

### Files
- ingress-prod.yaml            — Ingress for prod namespace
- ingress-staging.yaml         — Ingress for staging namespace
- ingress-path-updated.yaml    — path-ingress with default backend
- default-backend.yaml         — catchall deployment + service
- allow-from-dev-updated.yaml  — NetworkPolicy fix for staging
- prod-app-policy-updated.yaml — NetworkPolicy fix for prod
- INCIDENT-001.md              — 504 timeout incident log
