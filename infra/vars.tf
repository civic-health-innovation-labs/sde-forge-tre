variable "location" {
  type    = string
  default = "ukwest"
}

variable "user_number" {
  type = number
}

variable "image_version" {
  type = string
  default = "basic"

  validation {
    condition =  contains(["basic", "analysis"], var.image_version)
    error_message = "image_version must be basic or anaylsis"
  }
}

variable "vm_sku" {
  type    = string
  default = "Standard_D2ls_v5"
}

variable "tags" {
  type    = map(string)
  default = {}
}