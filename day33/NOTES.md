# Day 33 - Kubernetes Troubleshooting at Linux Level

## Tools used

crictl          → container runtime CLI (like docker ps but for containerd)
journalctl      → systemd journal logs for kubelet, containerd, kube-proxy
/proc/<pid>/    → inspect running container processes at Linux level
/sys/fs/cgroup/ → see actual resource limits enforced by kernel
iptables        → see service routing rules written by kube-proxy
conntrack       → see active connection tracking entries (DNAT translations)
systemctl       → manage and diagnose kubelet/containerd/kube-proxy

## crictl setup

Install: curl from kubernetes-sigs/cri-tools matching k8s version
Config:  /etc/crictl.yaml
         runtime-endpoint: unix:///run/containerd/containerd-k8s.sock
Alias:   alias crictl='sudo crictl'

## Scenario 1 - kubelet failure

Symptom:   kubectl get nodes → NotReady
           kubectl describe node → "Kubelet stopped posting node status"
           All conditions → Unknown
Diagnosis: systemctl status kubelet → inactive
           journalctl -u kubelet | tail -20
Fix:       sudo systemctl start kubelet
Key:       containers kept running after kubelet stopped
           kubelet and containerd are completely separate processes
           containerd manages container lifecycle
           kubelet manages pod lifecycle and heartbeats to API server

## Scenario 2 - containerd failure

Symptom:  brief "container runtime is down" in kubelet logs
Diagnosis: systemctl status containerd → restarted automatically
           systemctl cat containerd | grep Restart → Restart=always, RestartSec=5
Key:      containerd has Restart=always in systemd unit
          dies → systemd waits 5s → restarts automatically

## Scenario 3 - container inspection at Linux level

# Find container
crictl ps | grep <name>

# Get PID and cgroup path
sudo crictl inspect <container-id> | grep -E "pid|cgroupsPath"

# See actual process inside container
cat /proc/<pid>/cmdline | tr '\0' ' '

# See Linux namespaces isolating the container
sudo ls -la /proc/<pid>/ns

# Find cgroup memory limit
sudo find /sys/fs/cgroup -path "*<pod-uid>*" -name "memory.max"
sudo cat <path>/memory.max

## cgroup path reveals QoS class

/kubepods/besteffort/  → BestEffort → memory.max = max (unlimited)
/kubepods/burstable/   → Burstable  → memory.max = bytes value
/kubepods/guaranteed/  → Guaranteed → memory.max = exact limit

## Day 29 connection proven at Linux level

yaml: no resources    → QoS: BestEffort → memory.max: max
yaml: limits: 256Mi   → QoS: Burstable  → memory.max: 268435456

## Scenario 4 - iptables service routing

## Two tables

filter table → allow or deny traffic (Calico uses this for NetworkPolicy)
nat table    → rewrite source or destination addresses (kube-proxy uses this)

## DNAT vs SNAT

DNAT → changes DESTINATION address
       Pod calls ClusterIP → DNAT rewrites to real Pod IP
       kube-proxy uses this for all Service ClusterIPs

SNAT → changes SOURCE address
       Pod traffic leaving cluster → SNAT rewrites to node IP
       So external servers can reply back

## iptables chain structure for Services

PREROUTING
    ↓
cali-PREROUTING    ← Calico checks NetworkPolicy first
    ↓
KUBE-SERVICES      ← kube-proxy entry point, scans all ClusterIPs
    ↓
KUBE-SVC-XXXXXXXX  ← one chain per Service
    ↓
KUBE-SEP-XXXXXXXX  ← one chain per Pod endpoint (DNAT happens here)
    ↓
DNAT → destination rewritten to real Pod IP

## KUBE-MARK-MASQ

Appears in two places:
1. KUBE-SVC chain → marks traffic from OUTSIDE pod network for SNAT
2. KUBE-SEP chain → marks hairpin traffic (Pod calling its own Service)

## conntrack — the return journey

Linux connection tracking remembers every DNAT translation.
On return packet it automatically reverses the DNAT:
  Response from Pod IP → conntrack rewrites source back to ClusterIP
  Caller never sees the real Pod IP

## Real observations

conntrack entry format:
  src=<caller>  dst=<ClusterIP>    ← original direction
  src=<PodIP>   dst=<caller>       ← reply direction (DNAT reversed)

## Pod deleted → what happens to iptables

kube-proxy detects no endpoints
→ removes KUBE-SEP chain
→ removes KUBE-SVC chain
→ removes entry from KUBE-SERVICES
→ traffic to ClusterIP now has no rule → dropped silently

## "Incompatible with this kernel" error

Happens when kube-proxy is actively rewriting iptables mid-sync
Your read command hit a write lock
In production this is why large clusters use ipvs mode instead

## Key commands

sudo iptables -t nat -L PREROUTING -n
sudo iptables -t nat -L KUBE-SERVICES -n
sudo iptables -t nat -L KUBE-SVC-XXXXXXXX -n
sudo iptables -t nat -L KUBE-SEP-XXXXXXXX -n
sudo iptables -t nat -L -n | wc -l
sudo iptables -t nat -L -n | grep <ClusterIP>
sudo conntrack -L | grep <ClusterIP>
