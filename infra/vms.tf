
resource "azurerm_network_interface" "vm-main" {
  name                = "${module.azure_names.network_interface.name}-vm"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.vms.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_virtual_network.vnet]
  tags       = local.tags
}

resource "tls_private_key" "admin_key" {
  algorithm = "ED25519"
}

resource "tls_private_key" "analyst_key" {
  algorithm = "ED25519"
}


resource "random_password" "analyst_password" {
  length = 16
}

resource "azurerm_key_vault_secret" "admin_public_key" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-admin-public-key"
  value_wo         = tls_private_key.admin_key.public_key_openssh
  value_wo_version = 1
}


resource "azurerm_key_vault_secret" "admin_private_key" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-admin-private-key"
  value_wo         = tls_private_key.admin_key.private_key_openssh
  value_wo_version = 1
}

resource "azurerm_key_vault_secret" "analyst_public_key" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-analyst-public-key"
  value_wo         = tls_private_key.analyst_key.public_key_openssh
  value_wo_version = 1
}


resource "azurerm_key_vault_secret" "analyst_private_key" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-analyst-private-key"
  value_wo         = tls_private_key.analyst_key.private_key_openssh
  value_wo_version = 1
}

resource "azurerm_key_vault_secret" "vm_password" {
  key_vault_id     = azurerm_key_vault.kv.id
  name             = "vm-analyst-password"
  value_wo         = random_password.analyst_password.result
  value_wo_version = 1
}

module "vm_storage_account_name" {
  source = "../modules/storage-account-name"
  prefix = "sta-${local.resource_suffix}"
}

resource "azurerm_storage_account" "vm" {
  name                = module.vm_storage_account_name.storage_account_name
  location            = local.location
  resource_group_name = local.resource_group

  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action = "Allow"
    # virtual_network_subnet_ids = [azurerm_subnet.vms.id]
  }

  tags = local.tags
}

resource "azurerm_storage_container" "vm-common" {
  name               = "blob-${local.resource_suffix}-share"
  storage_account_id = azurerm_storage_account.vm.id
}


data "azurerm_image" "source-image" {
  name_regex          = "^sde-forge-${var.image_version}"
  resource_group_name = "rg-sde-forge"
  sort_descending     = true
}

resource "azurerm_linux_virtual_machine" "host" {

  name                  = "vm-${local.resource_suffix}-${var.user_number}"
  location              = local.location
  resource_group_name   = local.resource_group
  network_interface_ids = [azurerm_network_interface.vm-main.id]
  size                  = var.vm_sku


  custom_data = base64encode(templatefile(
    "${path.module}/files/cloud-init.yaml.tftpl", {
      ssh_authorized_key = tls_private_key.analyst_key.public_key_openssh
      plain_text_passwd  = random_password.analyst_password.result
    }
  ))


  admin_username = "azureadmin"
  admin_ssh_key {
    public_key = tls_private_key.admin_key.public_key_openssh
    username   = "azureadmin"
  }

  encryption_at_host_enabled = true
  # vtpm_enabled               = true

  provision_vm_agent = true

  #secure_boot_enabled = true

  identity {
    type = "SystemAssigned"
  }

  source_image_id = data.azurerm_image.source-image.id

  os_disk {
    caching                = "ReadWrite"
    disk_encryption_set_id = azurerm_disk_encryption_set.vm-des.id
    storage_account_type   = "StandardSSD_LRS"
  }

  tags = local.tags
}

resource "azurerm_virtual_machine_extension" "provision_data_mount" {
  name                       = "SetupDataMount"
  type                       = "CustomScript"
  publisher                  = "Microsoft.Azure.Extensions"
  virtual_machine_id         = azurerm_linux_virtual_machine.host.id
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    script = base64encode(templatefile("${path.module}/files/provision-data-mount.sh.tftpl", {
      storage_account = azurerm_storage_account.vm.name
      container_name  = azurerm_storage_container.vm-common.name
    })),
  })

  depends_on = [azurerm_role_assignment.vm-access-to-storage]
}

resource "azurerm_role_assignment" "vm-access-to-storage" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.host.identity[0].principal_id
  scope                = azurerm_storage_container.vm-common.id
}
