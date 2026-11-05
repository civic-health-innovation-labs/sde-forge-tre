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

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = "rg-sde-forge"
}

variable "rstudio_deb_url" {
  type        = string
  default     = "https://download1.rstudio.org/electron/jammy/amd64/rstudio-2026.09.0-174-amd64.deb"
  description = "Url of Ubuntu DEB for rstudio (see https://docs.posit.co/ide/user/#rstudio-ide-oss-downloads)"
}

variable "base_version" {
  type = string
}

source "azure-arm" "analysis_image" {
  use_azure_cli_auth = true
  os_type            = "Linux"


  shared_image_gallery_destination {
    resource_group = var.resource_group_name
    gallery_name   = "sig_sdeforge_2026"
    image_name     = "analysis"
    image_version  = formatdate("YYYY.MMDD.hhmm", timestamp())
  }

  shared_image_gallery {
    subscription   = var.subscription_id
    resource_group = var.resource_group_name
    gallery_name   = "sig_sdeforge_2026"
    image_name     = "basic"
    image_version  = "${var.base_version}"
  }

  azure_tags = {
    "Project"   = "sde-forge",
    "ImageType" = "analysis"
  }

  location = var.location
  vm_size  = "Standard_D2als_v6"
}

build {
  name    = "sde-forge-analysis"
  sources = ["source.azure-arm.analysis_image"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo sh -c ' {{ .Vars }} {{ .Path }}'"
    env = {
      "DEBIAN_FRONTEND" = "noninteractive"
    }
    inline = [
      "apt update -qq",
      "apt install -y --no-install-recommends software-properties-common dirmngr",
      "wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc",
      "add-apt-repository \"deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/\"",
      "apt install -y --no-install-recommends r-base",
      "wget -q -O /tmp/rstudio.deb ${var.rstudio_deb_url}",
      "apt install -y /tmp/rstudio.deb",
      "apt install -y libreoffice",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
  }
}