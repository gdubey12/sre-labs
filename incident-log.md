# SRE Incident Log
> Personal debugging log — one entry per real problem hit during lab sessions.
> Format: Date | Problem | Cause | Fix | Proof
> Use this directly for interview prep — STAR format answers live here.

---

## INC-001 — NetworkPolicy DNS Egress Blocked
**Date:** Day 19 — Kubernetes NetworkPolicy lab  
**Namespace:** staging  
**Pod affected:** backend (role=backend)

**Problem:**  
`backend` pod could not reach `db-svc` on port 5432. `curl` timed out with exit code 28. No connection error — just silence.

**Initial investigation:**  
- Checked `/etc/resolv.conf` inside backend pod → CoreDNS at `10.32.0.10`
- Ran `curl --max-time 5 http://db-svc:5432` → exit code 28 (timeout)
- tcpdump on worker-1 showed DNS query leaving pod's veth (`calicec12e244f7`) but **no reply ever came back**

**Root cause:**  
`allow-backend-egress` policy only allowed egress to `role=db` pods. The base `deny-all` policy blocked everything else including port 53 UDP/TCP to kube-system. DNS queries were sent but responses were dropped by Calico before reaching the pod. Without DNS, the hostname could not resolve — curl timed out instead of failing fast.

**Key distinction:**  
- Exit code **28** = timeout → NetworkPolicy blocking DNS (no response)  
- Exit code **6** = cannot resolve → DNS works but hostname doesn't exist  
- Exit code **7** = connection refused → DNS + routing works, app rejected it  

**Fix:**  
Updated `allow-backend-egress` to add two rules:
1. Egress to `kube-system` namespace on port 53 UDP+TCP (DNS)
2. Locked db egress to port 5432 only (was unrestricted before)

```yaml
egress:
- to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: kube-system
  ports:
  - port: 53
    protocol: UDP
  - port: 53
    protocol: TCP
- to:
  - podSelector:
      matchLabels:
        role: db
  ports:
  - port: 5432
```

**Proof:**  
- After fix: tcpdump showed DNS query → NXDomain reply (responses now arriving)
- curl exit code changed: 28 (timeout) → 7 (reached postgres, app rejected HTTP)
- Full TCP handshake visible in tcpdump: SYN → SYN-ACK → ACK → HTTP GET → 200 OK (frontend→backend)

**Lesson:**  
Any policy with `policyTypes: [Egress]` must explicitly allow port 53 UDP+TCP to kube-system. This is the #1 NetworkPolicy gotcha in production. Always add the DNS rule first, before any other egress rules.

---

## INC-002 — tcpdump Filter Missed Blocked Traffic
**Date:** Day 19 — Kubernetes NetworkPolicy lab  
**Namespace:** dev → staging

**Problem:**  
Running `tcpdump -i any host 10.200.226.73` (backend pod IP) showed nothing when `dev-intruder` tried to reach `backend-svc`. Expected to see blocked SYN packets but capture was empty.

**Root cause:**  
`dev-intruder` sent traffic to `10.32.0.29` (ClusterIP of backend-svc), not directly to `10.200.226.73` (backend pod IP). Calico dropped the packet **before kube-proxy could DNAT** the ClusterIP to the pod IP. So `10.200.226.73` never appeared in any packet — the tcpdump filter was correct but matched the wrong IP.

**Fix:**  
Changed filter to ClusterIP: `tcpdump -i any host 10.32.0.29`  
Also confirmed by tcpdumping dev-intruder's own veth (`calif526b983c51`) — saw SYN leaving source, retransmitting 3 times, no reply.

**Proof:**  
- `tcpdump -i any host 10.32.0.29` → SYN visible, no SYN-ACK (blocked)
- `tcpdump -i calicec12e244f7` (backend veth) → completely silent (drop happened before reaching destination veth)

**Lesson:**  
When debugging blocked pod→Service traffic, filter on **ClusterIP not pod IP**. DNAT only happens after Calico allows the packet. Blocked traffic never gets translated — the pod IP never appears in the capture.

---



## INC-003 — db Pod Had Unrestricted Egress
**Date:** Day 20  
**Namespace:** staging  
**Pod affected:** db (role=db)

**Problem:** allow-backend-to-db only had Ingress in policyTypes so db could send traffic to anyone outbound.

**Cause:** Egress policyType was missing — Kubernetes defaults to allow all egress when Egress is not listed in policyTypes.

**Fix:** Added Egress to policyTypes in allow-backend-to-db. No egress rules needed — empty Egress = deny all.

**Proof:** curl from db to example.com returned exit code 28. tcpdump showed DNS query leaving db veth but no reply — egress blocked at Calico.

## INC-004 — NetworkPolicy Port Mismatch (Service Port vs Pod Port)
**Date:** Day 20
**Namespace:** prod
**Pod affected:** web (role=web)

**Problem:** web → app-svc:8080 timed out (exit code 28) even though egress policy
looked correct and labels matched.

**Cause:** NetworkPolicy egress rule had port 8080 (Service port). But Calico
evaluates policy against the actual pod port AFTER kube-proxy DNAT. app pod
listens on port 80, not 8080. So Calico found no matching egress rule and dropped.

**Fix:** Changed egress port from 8080 to 80 (the pod's actual listening port).

**Proof:** curl to pod IP direct on port 80 worked. curl via service on 8080 worked
after fix. exit code 0.

**Lesson:** In NetworkPolicy always use the pod's listening port, not the Service
port. Service port mapping is irrelevant to policy evaluation.
