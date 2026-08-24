variable "location" {
  type    = string
  default = "ukwest"
}

variable "user_number" {
  type = number
}

variable "vm_sku" {
  type    = string
  default = "Standard_B2als_v2"
}

variable "tags" {
  type    = map(string)
  default = {}
}