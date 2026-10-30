# SRE Learning Labs

Hands-on Linux, Docker, CI/CD and Kubernetes labs focused on infrastructure operations, troubleshooting, automation and reliability engineering.

This repository documents practical work completed during a planned 90-day SRE learning journey. The original day numbering is retained to preserve the learning history; it does not imply that every day of the programme was completed.

## Learning Approach

The focus is on practical exercises rather than theory alone:

- Build and configure infrastructure components.
- Introduce controlled failures and investigate symptoms.
- Troubleshoot using Linux commands, logs and network tools.
- Document findings, recovery steps and operational lessons.
- Maintain reusable notes and runbooks.

## Technical Areas

### 1. Linux Administration and Troubleshooting

Hands-on exercises include:

- Process investigation using `ps`, `/proc`, `lsof` and `strace`.
- CPU-intensive and zombie process investigation.
- Disk capacity and inode exhaustion troubleshooting.
- Deleted-but-open file investigation.
- TCP connectivity and firewall troubleshooting.
- Bash health-check scripts, cron scheduling and webhook notifications.
- systemd service management, restart policies and cgroup memory limits.

### 2. Docker and Container Engineering

Labs cover:

- Container lifecycle, images, volumes and port mapping.
- Docker bridge networking and service discovery.
- Multi-container applications using Docker Compose.
- Dockerfile optimisation and multi-stage builds.
- Image layer caching and non-root container execution.
- Trivy image vulnerability scanning.
- Health checks, persistent PostgreSQL storage and service dependencies.
- Troubleshooting application failures and container recovery.

### 3. Git and CI/CD

Practical work includes:

- Git branching, commits, pull requests and merge workflows.
- Rebase, cherry-pick, interactive rebase and `git bisect`.
- GitHub Actions CI pipelines.
- Automated testing and Docker image builds.
- Matrix testing across Python versions.
- Dependency caching and pipeline status gates.
- Trivy security scanning and DockerHub image publishing.
- Failure notifications through webhooks.

Related project: [sre-cicd-app](https://github.com/gdubey12/sre-cicd-app)

### 4. Infrastructure as Code — Terraform Fundamentals

Exercises include:

- Terraform workflow: init, plan, apply and destroy.
- Variables, outputs and state management.
- Resource dependencies and reusable modules.
- State inspection and drift detection.
- GitLab HTTP backend and remote state concepts.

The exercises documented here include the Terraform local-file provider and remote-state practice; they should not be interpreted as production AWS provisioning experience.

### 5. Kubernetes Administration and Troubleshooting

Hands-on topics include:

- Pods, Deployments and Services.
- ConfigMaps, Secrets and NodePort.
- Rolling updates and rollout history.
- Ingress and application routing.
- Role-Based Access Control (RBAC).
- Resource requests, limits, LimitRange and ResourceQuota.
- Taints, tolerations and node affinity.
- Kubernetes troubleshooting using Linux, container runtime and networking tools.

### 6. Kubernetes Networking and Storage

Practical exercises and projects include:

- NetworkPolicy ingress and egress rules.
- Namespace and workload traffic isolation.
- StatefulSets and headless Services.
- PersistentVolumes and PersistentVolumeClaims.
- Per-pod storage using volumeClaimTemplates.
- Stable pod identity and DNS.
- Persistent data validation and recovery scenarios.

## Selected Hands-on Projects

### Stateful Guestbook Application

A multi-component Kubernetes application involving:

- Nginx frontend Deployment and NodePort Service.
- BusyBox backend StatefulSet.
- Headless Service and persistent storage.
- ConfigMaps and application configuration.
- ServiceAccount and RBAC.
- NetworkPolicies controlling application traffic.

**Documentation:** [Guestbook project notes](project1/NOTES.md)

**Manifests:** [Frontend](project1/frontend.yaml) · [Backend](project1/backend.yaml) · [ConfigMap](project1/configmap.yaml) · [Storage](project1/pv.yaml) · [RBAC](project1/rbac.yaml) · [NetworkPolicy](project1/netpol.yaml)

### StatefulSet and Persistent Storage

A separate exercise demonstrating:

- StatefulSet replicas and stable identities.
- Per-pod PersistentVolumeClaims.
- Headless Service DNS.
- Pod recreation and data persistence.
- PersistentVolume reclaim policy concepts.

**Documentation:** [StatefulSet lab notes](sts/NOTES.md)

**Manifests:** [StatefulSet](sts/sts-web.yaml) · [PersistentVolumes](sts/pvs.yaml) · [PVC](sts/pvc0.yaml)

### Kubernetes NetworkPolicy Exercises

Hands-on exercises covering Kubernetes network traffic control.

**Documentation:** [NetworkPolicy notes](networkpolicies/NOTES.md)

### Linux Monitoring Fundamentals

Exercises covering logs, metrics, Docker monitoring, networking observations and structured logging concepts.

**Documentation:** [Day 13 notes](day13/NOTES.md) · [Monitoring basics runbook](day13/runbooks/monitoring-basics.md)

### Git and CI/CD Automation

Hands-on Git and GitHub Actions exercises covering:

- Feature branches, pull requests and merge workflows.
- Rebase, cherry-pick, git bisect and interactive rebase.
- CI pipeline stages: test, Docker build, security scan and image push.
- Troubleshooting failed test and build stages.
- Pre-commit hooks and GitHub branch protection rules.
- Automated Docker image publishing to DockerHub.

**Documentation:** [Day 9 notes](day9/NOTES.md) · [Git and CI/CD runbook](day9/runbooks/git-cicd.md)

**Application repository:** [sre-cicd-app](https://github.com/gdubey12/sre-cicd-app)

## Tools and Technologies

| Area | Tools |
|---|---|
| Operating Systems | Linux, Ubuntu, RHEL-based distributions |
| Linux Troubleshooting | ps, top, lsof, strace, journalctl, systemd |
| Networking | curl, ss, nc, tcpdump, iptables, firewalld |
| Scripting | Bash, Python fundamentals |
| Containers | Docker, Docker Compose, Trivy |
| Version Control | Git, GitHub |
| CI/CD | GitHub Actions |
| Infrastructure as Code | Terraform fundamentals |
| Container Orchestration | Kubernetes |
| Kubernetes Networking | Services, Ingress, NetworkPolicy |
| Kubernetes Storage | PV, PVC, StatefulSet |

## Repository Structure

The original day-based folders are retained to preserve the progression of the learning exercises.

Additional folders contain projects, reference material, networking exercises and StatefulSet labs.

## Important Context

This is a personal hands-on learning repository. The labs and projects are separate from professional production responsibilities and are intended to demonstrate practical learning, troubleshooting methodology and technical development.

Professional experience and responsibilities are described separately in my resume and LinkedIn profile.
