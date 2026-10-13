packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.0.5"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}


variable "location" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "rg-sde-forge"
}

source "azure-arm" "ubuntu_lts" {
  use_azure_cli_auth                = true
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = "sde-forge-basic.${local.timestamp}"
  os_type                           = "Linux"
  image_publisher                   = "Canonical"
  image_offer                       = "ubuntu-26_04-lts"
  image_sku                         = "minimal"

  azure_tags = {
    "Project"   = "sde-forge",
    "ImageType" = "basic"
  }

  location = var.location
  vm_size  = "Standard_D2als_v6"
}

build {
  name    = "sde-forge-basic"
  sources = ["source.azure-arm.ubuntu_lts"]

  provisioner "shell" {
    inline = [
      "sudo wget https://packages.microsoft.com/config/ubuntu/26.04/packages-microsoft-prod.deb",
      "sudo dpkg -i packages-microsoft-prod.deb",
      "sudo rm packages-microsoft-prod.deb",
      "sudo DEBIAN_FRONTEND=noninteractive apt update",
      "yes | sudo unminimize",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y blobfuse2 xfce4 xfce4-session xrdp xterm",
      "curl -fsSL https://download.opensuse.org/repositories/isv:/BrowserWorks/xUbuntu_26.04/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/waterfox.gpg > /dev/null",
      "echo 'deb [signed-by=/usr/share/keyrings/waterfox.gpg] https://download.opensuse.org/repositories/isv:/BrowserWorks/xUbuntu_26.04/ /' | sudo tee /etc/apt/sources.list.d/waterfox.list",
      "sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt install waterfox",
      "sudo systemctl enable xrdp",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
  }
}