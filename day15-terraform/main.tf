terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "hello" {
 # content  = "Hello from Terraform!"
  content  = var.file_content
  filename = "/home/coolboy/labs/day15-terraform/hello.txt"
}
