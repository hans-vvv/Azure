terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
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

resource "azurerm_subnet" "vnet1-sub1" {
  name                 = "vnet1-sub1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "vnet1-sub2" {
  name                 = "vnet1-sub2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.1.1.0/24"]
}

module "vm1" {
  source               = "../vm_module"
  name                 = "vm1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub1.id]
}

module "vm11" {
  source               = "../vm_module"
  name                 = "vm11"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub1.id]
  first_nic_public_ip  = "no"  
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "vnet2-sub1" {
  name                 = "vnet2-sub1"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_subnet" "vnet2-sub2" {
  name                 = "vnet2-sub2"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.2.1.0/24"]
}

module "vm2" {
  source               = "../vm_module"
  name                 = "vm2"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  location             = azurerm_resource_group.rg-ne.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet2-sub1.id]
}

module "vm21" {
  source               = "../vm_module"
  name                 = "vm21"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  location             = azurerm_resource_group.rg-ne.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet2-sub1.id]
  first_nic_public_ip  = "no"  
}

resource "azurerm_virtual_network" "vng1-vnet" {
  name                = "vng1-vnet"
  address_space       = ["10.255.0.0/16"]
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
}

resource "azurerm_subnet" "vng1-gwsubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vng1-vnet.name
  address_prefixes     = ["10.255.0.0/24"]
}

resource "azurerm_subnet" "vng1-sub1" {
  name                 = "vng1-sub1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vng1-vnet.name
  address_prefixes     = ["10.255.1.0/24"]
}

resource "azurerm_subnet" "vng1-sub2" {
  name                 = "vng1-sub2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vng1-vnet.name
  address_prefixes     = ["10.255.2.0/24"]
}

module "vm100" {
  source               = "../vm_module"
  name                 = "vm100"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vng1-sub1.id, azurerm_subnet.vng1-sub2.id]
  second_nic_enabled   = true
}

# Enable IP forwarding
resource "null_resource" "update_nic1" {
  provisioner "local-exec" {
    command = "az network nic update --resource-group rg-we --name vm100-nic1 --ip-forwarding true"
  }
  depends_on = [module.vm100]
}

# Enable IP forwarding
resource "null_resource" "update_nic2" {
  provisioner "local-exec" {
    command = "az network nic update --resource-group rg-we --name vm100-nic2 --ip-forwarding true"
  }
  depends_on = [module.vm100]
}

resource "azurerm_public_ip" "vng1-public-ip" {
  name                = "vng1-public-ip"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "vng1" {
  name                = "vng1"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vng1-ipconf"
    public_ip_address_id          = azurerm_public_ip.vng1-public-ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng1-gwsubnet.id
  }  

  bgp_settings {
    asn       = 65515    
  }
}

resource "azurerm_virtual_network" "vng2-vnet" {
  name                = "vng2-vnet"
  address_space       = ["10.254.0.0/16"]
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
}

resource "azurerm_subnet" "vng2-gwsubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg-ne.name
  virtual_network_name = azurerm_virtual_network.vng2-vnet.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_public_ip" "vng2-public-ip" {
  name                = "vng2-public-ip"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "vng2" {
  name                = "vng2"
  location            = azurerm_resource_group.rg-ne.location
  resource_group_name = azurerm_resource_group.rg-ne.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vng2-ipconf"
    public_ip_address_id          = azurerm_public_ip.vng2-public-ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng2-gwsubnet.id
  }

  bgp_settings {
    asn       = 65516    
  }
}

resource "azurerm_virtual_network_gateway_connection" "vng1-vng2-connection" {
  name                        = "vng1-vng2-connection"
  location                    = azurerm_resource_group.rg-we.location
  resource_group_name         = azurerm_resource_group.rg-we.name
  virtual_network_gateway_id  = azurerm_virtual_network_gateway.vng1.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng2.id  
  shared_key                  = "Test123"
  type                        = "Vnet2Vnet"
  enable_bgp                  = true
  use_policy_based_traffic_selectors = false
}


resource "azurerm_virtual_network_gateway_connection" "vng2-vng1-connection" {
  name                        = "vng2-vng1-connection"
  location                    = azurerm_resource_group.rg-ne.location
  resource_group_name         = azurerm_resource_group.rg-ne.name
  virtual_network_gateway_id  = azurerm_virtual_network_gateway.vng2.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng1.id  
  shared_key                  = "Test123"
  type                        = "Vnet2Vnet"
  enable_bgp                  = true
  use_policy_based_traffic_selectors = false
  depends_on = [azurerm_virtual_network_gateway_connection.vng1-vng2-connection]
}

resource "azurerm_virtual_network_peering" "vng1-vnet-to-vnet1" {
  name                      = "vng1-vnet-to-vnet1"
  resource_group_name       = azurerm_resource_group.rg-we.name
  virtual_network_name      = azurerm_virtual_network.vng1-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false  
}

resource "azurerm_virtual_network_peering" "vnet1-to-vng1-vnet" {
  name                      = "vnet1-to-vng1-vnet"
  resource_group_name       = azurerm_resource_group.rg-we.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vng1-vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
  depends_on = [azurerm_virtual_network_peering.vng1-vnet-to-vnet1]
}

resource "azurerm_virtual_network_peering" "vng2-vnet-to-vnet2" {
  name                      = "vng2-vnet-to-vnet2"
  resource_group_name       = azurerm_resource_group.rg-ne.name
  virtual_network_name      = azurerm_virtual_network.vng2-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false  
}

resource "azurerm_virtual_network_peering" "vnet2-to-vng2-vnet" {
  name                      = "vnet2-to-vng2-vnet"
  resource_group_name       = azurerm_resource_group.rg-ne.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vng2-vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
  depends_on = [azurerm_virtual_network_peering.vng2-vnet-to-vnet2]
}

resource "azurerm_route_table" "rt-vnet1-sub2" {
  name                = "rt-vnet1-sub2"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
}

resource "azurerm_route" "route-to-fw" {
  name                   = "route-to-fw"
  resource_group_name    = azurerm_resource_group.rg-we.name
  route_table_name       = azurerm_route_table.rt-vnet1-sub2.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.255.2.4"
}

resource "azurerm_subnet_route_table_association" "vnet1-sub2-to-rt-vnet1-sub2-ass" {
  subnet_id      = azurerm_subnet.vnet1-sub2.id
  route_table_id = azurerm_route_table.rt-vnet1-sub2.id
}

