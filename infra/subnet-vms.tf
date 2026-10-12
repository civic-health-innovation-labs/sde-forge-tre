resource "azurerm_subnet" "vms" {
  name                 = "sn-${local.resource_suffix}-vms"
  virtual_network_name = azurerm_virtual_network.vnet.name

  resource_group_name = local.resource_group

  address_prefixes = [local.vm_cidr]

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_network_security_group" "vms" {
  name                = "${module.azure_names.network_security_group.name}-vms"
  resource_group_name = local.resource_group
  location            = var.location

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "vms" {
  network_security_group_id = azurerm_network_security_group.vms.id
  subnet_id                 = azurerm_subnet.vms.id
}

resource "azurerm_network_security_rule" "allow_bastion_ssh_outbound" {
  name                        = "AllowBastionOutbound"
  priority                    = 100
  direction                   = "Outbound"
  network_security_group_name = azurerm_network_security_group.vms.name
  resource_group_name         = azurerm_network_security_group.vms.resource_group_name
  access                      = "Allow"
  protocol                    = "Tcp"

  destination_address_prefixes = [local.bastion_cidr, "168.63.129.16"]
  destination_port_range       = "*"
  source_address_prefix        = "*"
  source_port_range            = "*"


}

resource "azurerm_network_security_rule" "allow_storage_https" {
  name      = "AllowStorageHTTPSOutbound"
  priority  = 110
  direction = "Outbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "Storage"

  resource_group_name         = azurerm_network_security_group.vms.resource_group_name
  network_security_group_name = azurerm_network_security_group.vms.name
}


resource "azurerm_network_security_rule" "deny_internet_outbound" {
  name                        = "DenyInternetOutbound"
  priority                    = 2000
  network_security_group_name = azurerm_network_security_group.vms.name
  resource_group_name         = azurerm_network_security_group.vms.resource_group_name
  access                      = "Deny"
  protocol                    = "*"
  destination_address_prefix  = "Internet"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"
  direction                   = "Outbound"
}

resource "azurerm_network_security_rule" "allow_bastion_ssh_inbound" {
  name                        = "AllowBastionSSHInbound"
  priority                    = 100
  network_security_group_name = azurerm_network_security_group.vms.name
  resource_group_name         = azurerm_network_security_group.vms.resource_group_name
  access                      = "Allow"
  protocol                    = "Tcp"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  source_address_prefixes     = [local.bastion_cidr]
  source_port_range           = "*"
  direction                   = "Inbound"
}

resource "azurerm_network_security_rule" "deny_internet_inbound" {
  name                        = "DenyInternetInbound"
  priority                    = 1000
  network_security_group_name = azurerm_network_security_group.vms.name
  resource_group_name         = azurerm_network_security_group.vms.resource_group_name
  access                      = "Deny"
  protocol                    = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  direction                   = "Inbound"
}
