

data "azurerm_client_config" "me" {}


locals {

  vnet_cidr    = "10.0.0.0/8"
  vm_cidr      = "10.0.0.0/24"
  bastion_cidr = "10.1.0.0/24"

  resource_suffix = "sde-forge"

  tenant_id = data.azurerm_client_config.me.tenant_id

  resource_group = var.resource_group_name
  location       = var.location

  tags = merge(var.tags, { "Project" = "sde-forge" })
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  address_space = [local.vnet_cidr]

  tags = local.tags
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-${local.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = local.tenant_id
  sku_name            = "standard"

  enabled_for_disk_encryption = true
  purge_protection_enabled    = true

  tags = local.tags
}

resource "azurerm_key_vault_key" "vm-encryption" {
  name         = "des-${local.resource_suffix}-vms"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_key_vault_access_policy.current-user
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
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.vm-encryption.id

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "des-vms" {
  key_vault_id = azurerm_key_vault.kv.id

  tenant_id = azurerm_disk_encryption_set.vm-des.identity[0].tenant_id
  object_id = azurerm_disk_encryption_set.vm-des.identity[0].principal_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "current-user" {
  key_vault_id = azurerm_key_vault.kv.id

  tenant_id = local.tenant_id
  object_id = data.azurerm_client_config.me.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "GetRotationPolicy",
  ]

  secret_permissions = [
    "Delete",
    "Get",
    "Set",
    "List",
    "Purge",
    "Restore"
  ]
}

resource "azurerm_role_assignment" "vm-des" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.vm-des.identity[0].principal_id
}
