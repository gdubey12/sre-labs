# NetworkPolicy Notes

## Core Concept
- No NetworkPolicy on pod = all traffic allowed (open by default)
- NetworkPolicy exists = ONLY what policy explicitly allows gets through
- Multiple policies on same pod = they COMBINE (union of all rules)

## The Bouncer Model
policyTypes declared  = bouncer standing at the door
No rules written      = bouncer + no guest list = DENY ALL
Empty rule {}         = bouncer + "let everyone in" = ALLOW ALL
Specific rule         = bouncer + named list = ALLOW MATCHING ONLY
No NetworkPolicy      = no bouncer = everything walks in freely

## policyTypes Behavior
policyTypes declared + no rules   = DENY
policyTypes declared + empty {}   = ALLOW ALL
policyTypes declared + specific   = ALLOW MATCHING ONLY
type NOT declared                 = not enforced = OPEN

## Selectors
podSelector (top-level)  = which pods this policy PROTECTS
podSelector (in from/to) = which pods are ALLOWED to talk
namespaceSelector        = which namespaces are allowed
AND logic = both selectors under same - from item (one dash)
OR logic  = two separate - from items (two dashes)

## Conntrack
- New connection (SYN)    = checked against policy rules
- Response traffic        = checked against conntrack state (RELATED,ESTABLISHED)
- Response traffic bypasses policy rules entirely
- Only need egress rule for NEW outbound connections

## tcpdump Patterns
ALLOWED traffic:
  SYN → SYN-ACK → ACK → data → FIN  (full handshake visible)
  packet appears TWICE (In on source veth, Out on dest veth)

BLOCKED traffic:
  SYN arrives, retried once, silence
  packet appears only on source veth (never forwarded)

## Common Gotchas
1. firewalld on CentOS conflicts with Calico - always disable it
2. br_netfilter module must be loaded for Calico to enforce policy
3. rp_filter=1 on cali interfaces drops asymmetric pod traffic
4. deny-all blocks BOTH ingress and egress - need separate rules for each
5. DNS (port 53) must be explicitly allowed when restricting egress
   otherwise pod DNS resolution breaks

## Lab Setup
Namespaces: dev, staging
Policies applied:
  deny-all              - blocks all ingress+egress in staging
  allow-from-dev        - allows dev/role=frontend → staging/role=backend
  allow-backend-egress  - allows staging/role=backend → staging/role=db only
  allow-backend-to-db   - allows staging/role=backend → staging/role=db ingress

## Traffic Matrix
frontend(dev) → backend(staging)  = ALLOWED
intruder(dev) → backend(staging)  = BLOCKED (wrong label)
nginx(default)→ backend(staging)  = BLOCKED (wrong namespace)
attacker(stg) → backend(staging)  = BLOCKED (same ns, deny-all)
backend(stg)  → db(staging)       = ALLOWED
backend(stg)  → frontend(dev)     = BLOCKED (egress policy)
backend(stg)  → internet          = BLOCKED (egress policy)
db(stg)       → backend(staging)  = BLOCKED (db egress denied)
