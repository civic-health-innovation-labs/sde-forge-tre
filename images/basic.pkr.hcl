packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.6.4"
    }
  }
}

variable "location" {
  type    = string
  default = "ukwest"
}

variable "resource_group_name" {
  type    = string
  default = "rg-sde-forge"
}

variable "version" {
  type    = string
  default = null
}

source "azure-arm" "ubuntu_lts" {
  use_azure_cli_auth = true

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-26_04-lts"
  image_sku       = "minimal"

  shared_image_gallery_destination {
    resource_group = var.resource_group_name
    gallery_name   = "sig_sdeforge_2026"
    image_name     = "basic"
    image_version  = var.version
  }

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
    execute_command = "chmod +x {{ .Path }}; sudo sh -c '{{ .Vars }} {{ .Path }}'"
    env = {
      "DEBIAN_FRONTEND" = "noninteractive"
    }
    inline = [
      "wget https://packages.microsoft.com/config/ubuntu/26.04/packages-microsoft-prod.deb",
      "dpkg -i packages-microsoft-prod.deb",
      "rm packages-microsoft-prod.deb",
      "apt update",
      "apt install -y blobfuse2",
      # #"yes | unminimize",
      "apt install -y xfce4 xfce4-session xrdp xterm",
      "curl -fsSL https://download.opensuse.org/repositories/isv:/BrowserWorks/xUbuntu_26.04/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/waterfox.gpg > /dev/null",
      "echo 'deb [signed-by=/usr/share/keyrings/waterfox.gpg] https://download.opensuse.org/repositories/isv:/BrowserWorks/xUbuntu_26.04/ /' | sudo tee /etc/apt/sources.list.d/waterfox.list",
      "apt update && apt install -y waterfox",
      "systemctl enable xrdp",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
  }
}