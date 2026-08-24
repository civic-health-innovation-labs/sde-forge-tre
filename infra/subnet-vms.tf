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
