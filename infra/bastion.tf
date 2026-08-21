
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name

  resource_group_name = local.resource_group

  # default_outbound_access_enabled = false # This is probably needed for live

  address_prefixes = [local.bastion_cidr]
}


resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-${local.resource_suffix}-bastion"
  resource_group_name = local.resource_group
  location            = local.location
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  network_security_group_id = azurerm_network_security_group.bastion.id
  subnet_id                 = azurerm_subnet.bastion.id

  # need to ensure the security group rules are created before the association
  depends_on = [
    azurerm_network_security_group.bastion,
    azurerm_network_security_rule.bastion-allow-internet,
    azurerm_network_security_rule.bastion-gateway-in,
    azurerm_network_security_rule.bastion-load-balancer-in,
    azurerm_network_security_rule.bastion-vnet-in,
    azurerm_network_security_rule.bastion-ssh-rdp-out,
    azurerm_network_security_rule.bastion-azcloud-out,
    azurerm_network_security_rule.bastion-vnet-out,
    azurerm_network_security_rule.bastion-http-out
  ]
}

# See https://docs.azure.cn/en-us/bastion/bastion-nsg?tabs=portal for Network Security Rules
# Azure seems to be pretty fussy when it comes to names and priorities

resource "azurerm_network_security_rule" "bastion-allow-internet" {
  name                        = "AllowHttpsInbound"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  description                = "Allow connections from internet"
  direction                  = "Inbound"
  priority                   = 120
  access                     = "Allow"
  source_address_prefix      = "Internet"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "443"
  protocol                   = "Tcp"

}

resource "azurerm_network_security_rule" "bastion-gateway-in" {
  name                        = "AllowGatewayManagerInbound"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Inbound"
  priority                   = 130
  access                     = "Allow"
  source_address_prefix      = "GatewayManager"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "443"
  protocol                   = "Tcp"
}

resource "azurerm_network_security_rule" "bastion-load-balancer-in" {
  name                        = "AllowAzureLoadBalancerInbound"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Inbound"
  priority                   = 140
  access                     = "Allow"
  source_address_prefix      = "AzureLoadBalancer"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "443"
  protocol                   = "Tcp"
}

resource "azurerm_network_security_rule" "bastion-vnet-in" {
  name                        = "AllowBastionHostCommunication"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Inbound"
  priority                   = 150
  access                     = "Allow"
  source_address_prefix      = "VirtualNetwork"
  source_port_range          = "*"
  destination_address_prefix = "VirtualNetwork"
  destination_port_ranges    = ["8080", "5701"]
  protocol                   = "*"
}

resource "azurerm_network_security_rule" "bastion-ssh-rdp-out" {
  name                        = "AllowSshRdpOutbound"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Outbound"
  priority                   = 100
  access                     = "Allow"
  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "VirtualNetwork" # this needs to be VirtualNetwork and not a specific IP Range
  destination_port_ranges    = ["22", "3389"]
  protocol                   = "Tcp"
}

resource "azurerm_network_security_rule" "bastion-azcloud-out" {
  name                        = "AllowAzureCloudOutbound"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Outbound"
  priority                   = 110
  access                     = "Allow"
  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "AzureCloud"
  destination_port_range     = "443"
  protocol                   = "Tcp"
}

resource "azurerm_network_security_rule" "bastion-vnet-out" {
  name                        = "AllowBastionCommunication"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Outbound"
  priority                   = 120
  access                     = "Allow"
  source_address_prefix      = "VirtualNetwork"
  source_port_range          = "*"
  destination_address_prefix = "VirtualNetwork"
  destination_port_ranges    = ["8080", "5701"]
  protocol                   = "*"
}

resource "azurerm_network_security_rule" "bastion-http-out" {
  name                        = "AllowHttpOutbound"
  resource_group_name         = local.resource_group
  network_security_group_name = azurerm_network_security_group.bastion.name

  direction                  = "Outbound"
  priority                   = 130
  access                     = "Allow"
  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "Internet"
  destination_port_range     = "80"
  protocol                   = "*"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bstn-${local.resource_suffix}"
  resource_group_name = local.resource_group
  location            = local.location

  sku = "Developer"

  virtual_network_id = azurerm_virtual_network.vnet.id

  tags = local.tags
}
