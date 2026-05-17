terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/82273206/terraform/state/day17-state"
    lock_address   = "https://gitlab.com/api/v4/projects/82273206/terraform/state/day17-state/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/82273206/terraform/state/day17-state/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
