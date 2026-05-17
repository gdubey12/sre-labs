terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "hello" {
  filename = "/home/coolboy/labs/day17-terraform/hello.txt"
  content  = "Remote state is working!"
}
