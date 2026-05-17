# Runbook: Terraform Modules & Multiple Resources (Day 16)

## Purpose
Reference guide for structuring Terraform with multiple resources, dependencies, and reusable modules.

---

## Prerequisites
- Terraform v1.15.3+ installed
- Day 15 complete (core workflow understood)
- Working directory: `~/labs/day16-terraform/`

---

## Project Structure

```
day16-terraform/
├── main.tf                        # Root config — calls modules, declares outputs
├── modules/
│   └── config-file/
│       └── main.tf                # Reusable module — variables + resource + output
├── config/
│   ├── app.conf
│   ├── db.conf
│   └── cache.conf
├── .terraform/                    # Downloaded plugins (auto-generated, gitignored)
├── .terraform.lock.hcl            # Plugin lockfile (commit this)
└── terraform.tfstate              # State file (never edit, gitignored)
```

---

## Multiple Resources & Dependencies

### Parallel resources (no dependency)
```hcl
resource "local_file" "app_config" {
  content  = "APP_ENV=production\nAPP_PORT=8080"
  filename = "/home/coolboy/labs/day16-terraform/config/app.conf"
}

resource "local_file" "db_config" {
  content  = "DB_HOST=localhost\nDB_PORT=5432"
  filename = "/home/coolboy/labs/day16-terraform/config/db.conf"
}
```
These have no dependency — Terraform creates them in parallel.

### Implicit dependency via interpolation
```hcl
resource "local_file" "summary" {
  content  = "App: ${local_file.app_config.filename}, DB: ${local_file.db_config.filename}"
  filename = "/home/coolboy/labs/day16-terraform/config/summary.txt"
}
```
Terraform detects the dependency from the `${}` reference automatically.

### Explicit dependency via depends_on
```hcl
resource "local_file" "summary" {
  content    = "..."
  filename   = "..."
  depends_on = [local_file.app_config, local_file.db_config]
}
```
Use when the dependency isn't expressed through attribute references.

---

## Modules

### What is a module?
Any folder containing `.tf` files. No special declaration needed.

### Module structure
```hcl
# modules/config-file/main.tf

variable "filename" {
  description = "Path of the file to create"
  type        = string
}

variable "content" {
  description = "Content to write into the file"
  type        = string
}

resource "local_file" "this" {
  content  = var.content
  filename = var.filename
}

output "file_path" {
  value = local_file.this.filename
}
```

### Calling a module
```hcl
# root main.tf

module "app_config" {
  source   = "./modules/config-file"    # path to module folder
  filename = "/home/coolboy/.../app.conf"
  content  = "APP_ENV=production\nAPP_PORT=8080"
}
```

### Module block anatomy
| Field | Purpose |
|---|---|
| `module "<name>"` | Your label for this call — tracked in state |
| `source` | Path to module (local) or registry URL (remote) |
| Other fields | Inputs — must match `variable` blocks in the module |

### Using module outputs in root
```hcl
output "all_configs" {
  value = {
    app   = module.app_config.file_path
    db    = module.db_config.file_path
    cache = module.cache_config.file_path
  }
}
```

### Passing module outputs to other modules
```hcl
module "database" {
  source = "./modules/database"
}

module "app" {
  source   = "./modules/app"
  db_host  = module.database.host    # output from database module
  db_port  = module.database.port
}
```

---

## When to Run terraform init

| Scenario | init needed? |
|---|---|
| New `module` block (local or remote) | YES |
| New `provider` | YES |
| First project setup | YES |
| New resource inside existing module | NO |
| Changing variable values | NO |
| Modifying resource arguments | NO |

---

## State Addresses

Resources inside modules are tracked with full path:
```
module.<module_call_name>.<resource_type>.<resource_name>
```
Example:
```
module.app_config.local_file.this
module.db_config.local_file.this
```

### IMPORTANT — Refactoring warning
Moving a direct resource into a module changes its state address.
Terraform will **destroy and recreate** it unless you rename the address:
```bash
terraform state mv local_file.app_config module.app_config.local_file.this
```

---

## Common Patterns

### Adding a new config via module (3 steps)
1. Add module block to root `main.tf`
2. Run `terraform init`
3. Run `terraform apply`

### Checking what outputs a module exposes
```bash
terraform output
terraform output all_configs
```

### Listing all resources in state
```bash
terraform state list
```

---

## Safety Rules
- Always read `terraform plan` before apply
- Watch the summary line: `Plan: X to add, Y to change, Z to destroy`
- Unexpected destroy count = stop and investigate
- Never edit `terraform.tfstate` manually
- Never commit `terraform.tfstate` to git
