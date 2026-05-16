# Day 16 — Terraform Modules & Multiple Resources

## Topics Covered
- Multiple resources and resource dependencies
- `depends_on` — explicit dependency declaration
- Resource interpolation — referencing attributes across resources
- Terraform dependency graph — parallel vs sequential resource creation
- Modules — reusable resource templates
- Module inputs (variables) and outputs
- Passing module outputs to other modules
- When to run `terraform init` (any new module block, local or remote)

## Key Concepts

### Resource Dependencies
Terraform builds a dependency graph automatically from interpolation references.
Resources with no dependency on each other are created in parallel.
`depends_on` is used when the dependency isn't expressed through attribute references.

### Modules
A module is any folder containing `.tf` files.
- `variable` blocks = inputs (what the caller passes in)
- `resource` blocks = the logic (what gets created)
- `output` blocks = return values (what the caller can read back)

### Module naming in state
Resources inside modules are tracked with full path addresses:
`module.<module_call_name>.<resource_type>.<resource_name>`
Example: `module.app_config.local_file.this`

### When terraform init is required
- Any new `module` block (local or remote)
- Any new `provider`
- First time setting up a project
- NOT needed when adding resources inside existing modules

### Output flow
Module outputs surface values to the root configuration.
Root can collect outputs from multiple modules into a single output map.

## Commands Used
```bash
terraform init        # required after adding any new module block
terraform plan        # dry run — always check destroy count
terraform apply -auto-approve   # apply without prompt (dev only)
terraform output      # query outputs without running apply
```

## Files Created
- `day16-terraform/main.tf` — root config with 3 module calls + output
- `day16-terraform/modules/config-file/main.tf` — reusable module
- `day16-terraform/config/app.conf`
- `day16-terraform/config/db.conf`
- `day16-terraform/config/cache.conf`

## Lessons Learned
- Refactoring direct resources into modules changes their state address
  → Terraform destroys and recreates unless `terraform state mv` is used
- Always read plan output before apply — unexpected destroy count = warning signal
- Module outputs are how Terraform wires infrastructure together
  → App module can receive DB host from database module output automatically
