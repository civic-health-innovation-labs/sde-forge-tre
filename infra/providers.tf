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
    storage_account_name = "stasdeforgeprdfrg"
    # container_name = "CHANGE_ME"
    key = "sde-forge.tfstate"
  }

}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
}
