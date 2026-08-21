terraform {

  required_version = "~>1.15"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.7"
    }
    assert = {
      source  = "hashicorp/assert"
      version = "~>0.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.3"
    }
  }

  backend "azurerm" {
    use_azuread_auth     = true
    storage_account_name = "statrewsprdgn"
    # container_name = "CHANGE_ME"
    key = "sde-forge.tfstate"
  }

}

provider "azurerm" {
  features {
  }
  storage_use_azuread = true
}
