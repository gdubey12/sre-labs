# Runbook: Terraform Basics (Day 15)

## Purpose
Reference guide for Terraform core workflow — init, plan, apply, destroy, variables, outputs, and state management.

---

## Prerequisites
- Ubuntu 22.04 VM (`192.168.31.21`)
- Terraform v1.15.3+ installed
- Working directory: `~/labs/day15-terraform/`

---

## Installation (one-time)

```bash
# Install dependencies
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add HashiCorp repo
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt-get update && sudo apt-get install -y terraform

# Verify
terraform version
```

---

## Core Workflow

### 1. Project structure
```
day15-terraform/
├── main.tf            # Resource definitions
├── variables.tf       # Variable declarations
├── outputs.tf         # Output declarations
├── terraform.tfvars   # Variable values (do not commit secrets)
├── .terraform/        # Downloaded plugins (auto-generated)
├── .terraform.lock.hcl # Plugin version lockfile (commit this)
└── terraform.tfstate  # State file (never edit manually)
```

### 2. Initialize
```bash
terraform init
```
- Downloads provider plugins declared in `main.tf`
- Creates `.terraform.lock.hcl`
- Run once per project, and again if providers change

### 3. Plan (dry run)
```bash
terraform plan
```
- Refreshes state against real infrastructure
- Compares desired state (`.tf` files) vs actual state
- Shows what will be added `+`, changed `~`, or destroyed `-`
- **Always read the summary line before applying:**
  ```
  Plan: X to add, Y to change, Z to destroy.
  ```

### 4. Apply
```bash
terraform apply
```
- Shows plan again, prompts for confirmation
- Type `yes` to proceed
- Updates `terraform.tfstate` after completion

```bash
# Apply without interactive prompt (use in CI pipelines)
terraform apply -auto-approve
```

### 5. Destroy
```bash
terraform destroy
```
- Removes all resources managed by this configuration
- Updates state file to empty
- Irreversible — always review the plan output first

---

## Variables

### Declare in `variables.tf`
```hcl
variable "file_content" {
  description = "Content to write into the file"
  type        = string
  default     = "Hello from Terraform!"
}
```

### Supply values via `terraform.tfvars`
```hcl
file_content = "Hello from tfvars!"
```

### Variable precedence (lowest → highest)
| Source | Example |
|---|---|
| `default` in variables.tf | fallback value |
| `terraform.tfvars` | overrides default |
| Environment variable | `export TF_VAR_file_content="value"` |
| `-var` CLI flag | `terraform apply -var="file_content=value"` |

### Reference in resources
```hcl
content = var.file_content
```

---

## Outputs

### Declare in `outputs.tf`
```hcl
output "file_location" {
  description = "Path of the created file"
  value       = local_file.hello.filename
}
```

### Query outputs anytime
```bash
terraform output
terraform output file_location
```

---

## State File

### Key facts
- Lives at `terraform.tfstate`
- Terraform's memory of what it created
- **Never edit manually**
- In teams — store in shared backend (S3, Terraform Cloud)
- `serial` field increments on every state change

### Detect drift manually
```bash
terraform plan
```
- Terraform refreshes state on every plan/apply
- If real infra differs from state, plan shows the diff
- This is how config drift is detected

### Inspect state
```bash
# List all managed resources
terraform state list

# Show details of a specific resource
terraform state show local_file.hello
```

---

## Disk Space Maintenance (encountered Day 15)

If VM disk usage is high:
```bash
# Check overall usage
df -h /

# Find large directories
du -sh /var/lib/* | sort -rh | head

# Clean Docker/containerd leftovers
docker system prune -a

# Clean apt cache
sudo apt-get clean

# Trim system logs to 100MB
sudo journalctl --vacuum-size=100M
```

---

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| `Error: Failed to install provider` | No internet or wrong repo | Check network, re-run `terraform init` |
| `Error: State file locked` | Another apply running | Wait or run `terraform force-unlock <id>` |
| `No such file or directory: terraform.tfstate` | Never applied yet | Run `terraform apply` first |
| `Error: Resource already exists` | State out of sync | Run `terraform import` or `terraform refresh` |

---

## Coming Up
- Day 50+: Terraform with LocalStack (simulated AWS) and real AWS free tier
- Terraform modules — reusable resource groups
- Remote state backends — S3 + DynamoDB locking
