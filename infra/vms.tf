
resource "azurerm_network_interface" "vm-main" {
  name                = "nic-${local.resource_suffix}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.vms.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

resource "tls_private_key" "admin_key" {
  algorithm = "ED25519"
}

resource "azurerm_key_vault_secret" "vm_public_key" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-admin-public-key"
  value_wo         = tls_private_key.admin_key.public_key_openssh
  value_wo_version = 1
}


resource "azurerm_key_vault_secret" "vm_private_key" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-admin-private-key"
  value_wo         = tls_private_key.admin_key.private_key_openssh
  value_wo_version = 1
}


module "vm_storage_account_name" {
  source = "../modules/storage-account-name"
  prefix = "sta-${local.resource_suffix}"
}

resource "azurerm_storage_account" "vm" {
  name                = module.vm_storage_account_name.storage_account_name
  location            = var.location
  resource_group_name = var.resource_group_name

  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.vms.id]
  }

  tags = local.tags
}

resource "azurerm_storage_share" "vm-common" {
  name               = "ss-${local.resource_suffix}-share"
  quota              = 5
  storage_account_id = azurerm_storage_account.vm.id
}


resource "azurerm_linux_virtual_machine" "host" {

  name                  = "vm-${local.resource_suffix}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.vm-main.id]
  size                  = var.vm_sku

  admin_username = "azureadmin"
  admin_ssh_key {
    public_key = tls_private_key.admin_key.public_key_openssh
    username = "azureadmin"
  }

  encryption_at_host_enabled = true
  vtpm_enabled               = true

  provision_vm_agent        = true

  secure_boot_enabled = true

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-26_04-lts"
    sku       = "minimal"
    version   = "latest"
  }

  os_disk {
    caching                = "ReadWrite"
    disk_encryption_set_id = azurerm_disk_encryption_set.vm-des.id
    storage_account_type   = "StandardSSD_LRS"
  }

  tags = local.tags
}

