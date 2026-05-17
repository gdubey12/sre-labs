# Runbook — Terraform Remote State

## Check what's in state
terraform state list
terraform state show <resource_name>

## Detect drift
terraform plan
# Look for unexpected + create or ~ update symbols

## Fix drift
terraform apply -auto-approve

## State locked and won't release
# Someone's apply crashed mid-run. Force unlock:
terraform force-unlock <LOCK_ID>
# Get LOCK_ID from the error message Terraform shows

## Lost backend credentials
# Re-run init with correct credentials:
terraform init \
  -backend-config="username=YOUR_USERNAME" \
  -backend-config="password=YOUR_TOKEN"
