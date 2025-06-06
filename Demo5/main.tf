terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.20"
    }
  }
}
provider "azurerm" {
  features {}
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "The admin password for the VM"
  type        = string
}


resource "azurerm_resource_group" "rg-we" {
  name     = "rg-we"
  location = "West Europe"
}

resource "azurerm_resource_group" "rg-ne" {
  name     = "rg-ne"
  location = "North Europe"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_public_ip" "vng1-public-ip1" {
  name                = "vng1-public-ip1"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_subnet" "vng1-gwsubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_virtual_network_gateway" "vng1" {
  name                = "vng1"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name

  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  active_active       = false
  enable_bgp          = true

  ip_configuration {
    name                          = "vng1-ipconf1"
    public_ip_address_id          = azurerm_public_ip.vng1-public-ip1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng1-gwsubnet.id
  }
  bgp_settings {
    asn       = 65010
  }
}

resource "null_resource" "wait_for_vng2_ip" {
  depends_on = [azurerm_public_ip.vng2-public-ip1]
  triggers = {
    ip = azurerm_public_ip.vng2-public-ip1.ip_address
  }
}

resource "azurerm_local_network_gateway" "lng_2" {
  name                = "lng-2"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name

  gateway_address     = null_resource.wait_for_vng2_ip.triggers.ip
  address_space       = ["10.3.0.0/16"]

  bgp_settings {
    asn                 = 65030
    bgp_peering_address = "10.3.0.254"
  }
  depends_on = [azurerm_virtual_network_gateway.vng2]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "vnet2-sub1" {
  name                 = "vnet2-sub1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.2.0.0/24"]
}

module "vm1" {
  source               = "../vm_module"
  name                 = "vm1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet2-sub1.id]
}

resource "azurerm_virtual_network" "vnet3" {
  name                = "vnet3"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
  address_space       = ["10.3.0.0/16"]
}

resource "azurerm_public_ip" "vng2-public-ip1" {
  name                = "vng2-public-ip1"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_subnet" "vng2-gwsubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  virtual_network_name = azurerm_virtual_network.vnet3.name
  address_prefixes     = ["10.3.0.0/24"]
}

resource "azurerm_virtual_network_gateway" "vng2" {
  name                = "vng2"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name

  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  active_active       = false
  enable_bgp          = true

  ip_configuration {
    name                          = "vng2-ipconf1"
    public_ip_address_id          = azurerm_public_ip.vng2-public-ip1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng2-gwsubnet.id
  }

  bgp_settings {
    asn       = 65030
  }
}

resource "null_resource" "wait_for_vng1_ip" {
  depends_on = [azurerm_public_ip.vng1-public-ip1]
  triggers = {
    ip = azurerm_public_ip.vng1-public-ip1.ip_address
  }
}

resource "azurerm_local_network_gateway" "lng_1" {
  name                = "lng-1"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  gateway_address     = null_resource.wait_for_vng1_ip.triggers.ip

  address_space       = ["10.1.0.0/16"]

  bgp_settings {
    asn                 = 65010
    bgp_peering_address = "10.1.0.254"
  }
  depends_on = [azurerm_virtual_network_gateway.vng1]
}

resource "azurerm_virtual_network" "vnet4" {
  name                = "vnet4"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
  address_space       = ["10.4.0.0/16"]
}

resource "azurerm_subnet" "vnet4-sub1" {
  name                 = "vnet4-sub1"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  virtual_network_name = azurerm_virtual_network.vnet4.name
  address_prefixes     = ["10.4.0.0/24"]
}

module "vm2" {
  source               = "../vm_module"
  name                 = "vm2"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  location             = azurerm_resource_group.rg-ne.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet4-sub1.id]
}


resource "azurerm_virtual_network_gateway_connection" "vng1-to-vng2" {
  name                       = "vng1-to-vng2"
  location                   = azurerm_resource_group.rg-we.location
  resource_group_name        = azurerm_resource_group.rg-we.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng1.id
  local_network_gateway_id   = azurerm_local_network_gateway.lng_2.id
  type                       = "IPsec"
  enable_bgp                 = true
  shared_key                 = "YourSharedSecret123!"
}

resource "azurerm_virtual_network_gateway_connection" "vng2-to-vng1" {
  name                       = "vng2-to-vng1"
  location                   = azurerm_resource_group.rg-ne.location
  resource_group_name        = azurerm_resource_group.rg-ne.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng2.id
  local_network_gateway_id   = azurerm_local_network_gateway.lng_1.id
  type                       = "IPsec"
  enable_bgp                 = true
  shared_key                 = "YourSharedSecret123!"
}

resource "azurerm_virtual_network_peering" "vnet1-to-vnet2" {
  name                      = "vnet1-to-vnet2"
  resource_group_name       = azurerm_resource_group.rg-we.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet2-to-vnet1" {
  name                      = "vnet2-to-vnet1"
  resource_group_name       = azurerm_resource_group.rg-we.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true

  depends_on = [azurerm_virtual_network_peering.vnet1-to-vnet2]
}

resource "azurerm_virtual_network_peering" "vnet3-to-vnet4" {
  name                      = "vnet3-to-vnet4"
  resource_group_name       = azurerm_resource_group.rg-ne.name
  virtual_network_name      = azurerm_virtual_network.vnet3.name
  remote_virtual_network_id = azurerm_virtual_network.vnet4.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet4-to-vnet3" {
  name                      = "vnet4-to-vnet3"
  resource_group_name       = azurerm_resource_group.rg-ne.name
  virtual_network_name      = azurerm_virtual_network.vnet4.name
  remote_virtual_network_id = azurerm_virtual_network.vnet3.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true

  depends_on = [azurerm_virtual_network_peering.vnet3-to-vnet4]
}








