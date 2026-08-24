

module "names" {
  source      = "../modules/names"
  user_number = var.user_number
  prefix      = local.resource_suffix
}

data "azurerm_client_config" "me" {}
data "azuread_group" "my_group" {
  display_name = module.names.group_name
}

module "azure_names" {
  source = "Azure/naming/azurerm"
  suffix = [local.resource_suffix, "${var.user_number}"]
}


locals {

  vnet_cidr    = "10.0.0.0/8"
  vm_cidr      = "10.0.0.0/24"
  bastion_cidr = "10.1.0.0/24"

  resource_suffix = "sde-forge"

  tenant_id = data.azurerm_client_config.me.tenant_id

  resource_group = module.names.resource_group_name
  location       = var.location

  tags = merge(var.tags, { "Project" = "sde-forge" })
}

resource "azurerm_virtual_network" "vnet" {
  name                = module.azure_names.virtual_network.name
  resource_group_name = local.resource_group
  location            = var.location

  address_space = [local.vnet_cidr]

  tags = local.tags
}

resource "azurerm_key_vault" "kv" {
  name                = module.azure_names.key_vault.name_unique
  resource_group_name = local.resource_group
  location            = var.location
  tenant_id           = local.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true

  enabled_for_disk_encryption = true
  purge_protection_enabled    = true

  tags = local.tags
}

resource "azurerm_role_assignment" "des_kv_access" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id = azurerm_disk_encryption_set.vm-des.identity[0].principal_id
}

resource "azurerm_role_assignment" "group_kv_admin" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id = data.azuread_group.my_group.object_id
}

resource "azurerm_key_vault_key" "vm-encryption" {
  name         = "des-${local.resource_suffix}-vms"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_role_assignment.group_kv_admin
  ]

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

resource "azurerm_disk_encryption_set" "vm-des" {
  name                = "des-${local.resource_suffix}-vms"
  resource_group_name = local.resource_group
  location            = local.location
  key_vault_key_id    = azurerm_key_vault_key.vm-encryption.id

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

