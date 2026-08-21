variable "location" {
  type     = string
  nullable = false
  default = "ukwest"
}

variable "resource_group_name" {
  type = string
  nullable = false
}

variable "vm_sku" {
  type     = string
  nullable = false
  default  = "Standard_B2als_v2"
}

variable "tags" {
  type = map(string)
  default = {}
}