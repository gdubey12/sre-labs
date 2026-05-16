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
