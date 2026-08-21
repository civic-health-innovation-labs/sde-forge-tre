variable "user_number" {
  type = number
}

variable "prefix" {
  type = string
}

locals {
  default = "${var.prefix}-user-${var.user_number}"
}

output "group_name" {
  value = local.default
}

output "state_container" {
  value = "blob-${local.default}"
}

output "resource_group_name" {
  value = "rg-${local.default}"
}