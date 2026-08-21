variable "prefix" {
  type     = string
  nullable = false
}

locals {
  real_prefix = replace(lower(var.prefix), "/[^0-9a-z]/", "")
}

resource "random_string" "suffix" {
  length  = 24 - length(local.real_prefix)
  upper   = false
  special = false
}

output "storage_account_name" {
  value = "${local.real_prefix}${random_string.suffix.result}"
}
