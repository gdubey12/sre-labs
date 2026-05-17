# Day 17 — Terraform Remote State

## What I did
- Configured GitLab HTTP backend for remote state storage
- Ran terraform init with backend credentials
- Verified state stored in GitLab (Operate → Terraform states)
- Confirmed no terraform.tfstate file locally
- Simulated drift by manually editing hello.txt
- Terraform plan detected drift via SHA1 hash mismatch
- Terraform apply restored correct state

## Key concepts
- state serial: increments on every apply, prevents conflicts
- state lineage: unique ID, prevents mixing state between projects
- state lock: acquired before plan/apply, released after — prevents concurrent applies
- remote state: state lives in GitLab, not on local VM
- drift detection: Terraform compares hash in state vs actual file on disk

## Commands used
- terraform state list
- terraform state show <resource>
- terraform init -backend-config="username=..." -backend-config="password=..."
- terraform plan
- terraform apply -auto-approve

## Backend config location
GitLab project: terraform-state (ID: 82273206)
State name: day17-state
