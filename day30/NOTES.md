# Day 30 - Taints, Tolerations, Node Affinity

## Mental Model

Taints/Tolerations → Node pushes Pods away (repulsion)
Node Affinity      → Pod pulls toward specific Nodes (attraction)

## Taints

Applied to a Node. Repels Pods that don't tolerate it.

kubectl taint nodes <node> key=value:Effect
kubectl taint nodes <node> key=value:Effect-   # remove taint (note the -)

Three effects:
- NoSchedule      → new Pods without toleration won't schedule here
- PreferNoSchedule → scheduler avoids but not guaranteed
- NoExecute       → new Pods rejected + existing Pods evicted

## Tolerations

Applied to a Pod. Grants permission to land on a tainted node.

tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "monitoring"
  effect: "NoSchedule"

Important: toleration = permission only, not guaranteed placement.
Scheduler still picks based on capacity.

## Node Affinity

Applied to a Pod. Attracts Pod toward nodes with specific labels.

Two types:
- requiredDuringSchedulingIgnoredDuringExecution → hard rule, Pod stays Pending if no match
- preferredDuringSchedulingIgnoredDuringExecution → soft rule, best effort

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disktype
          operator: In
          values:
          - ssd

## Node labels

kubectl label node <node> key=value          # add label
kubectl label node <node> key=value-         # remove label
kubectl describe node <node> | grep Labels   # check labels

## Scheduling failure messages

Taint rejection:    "node(s) had untolerated taint"
Affinity rejection: "node(s) didn't match Pod's node affinity/selector"

## Real world pattern — dedicated node

Node:  tainted gpu=true:NoSchedule  +  labelled hardware=gpu
Pod:   tolerates gpu=true:NoSchedule  +  affinity for hardware=gpu
Result: only that Pod lands on GPU node, everything else repelled

## Lab files

- no-toleration-pod.yaml  → stayed Pending (untolerated taint)
- with-toleration-pod.yaml → Running (toleration matched)
- affinity-pod.yaml        → Running (disktype=ssd matched)
- affinity-fail-pod.yaml   → Pending (disktype=nvme not found)
