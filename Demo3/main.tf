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

# resource "azurerm_resource_group" "rg-ne" {
#   name     = "rg-ne"
#   location = "North Europe"
# }

# resource "azurerm_virtual_network" "vnet1" {
#   name                = "vnet1"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   address_space       = ["10.1.0.0/16"]
# }

# resource "azurerm_subnet" "vnet1-sub1" {
#   name                 = "vnet1-sub1"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   virtual_network_name = azurerm_virtual_network.vnet1.name
#   address_prefixes     = ["10.1.0.0/24"]
# }

# module "vm7" {
#   source               = "../vm_module"
#   name                 = "vm7"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   location             = azurerm_resource_group.rg-we.location
#   admin_username       = var.admin_username
#   admin_password       = var.admin_password
#   subnet_ids           = [azurerm_subnet.vnet1-sub1.id]
# }

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

resource "azurerm_subnet" "vnet2-sub2" {
  name                 = "vnet2-sub2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_subnet" "vnet2-sub3" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.2.2.0/24"]
}

# resource "azurerm_public_ip" "vng1-public-ip1" {
#   name                = "vng1-public-ip1"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   sku                 = "Standard"
#   allocation_method   = "Static"
# }

# resource "azurerm_public_ip" "vng1-public-ip2" {
#   name                = "vng1-public-ip2"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   sku                 = "Standard"
#   allocation_method   = "Static"
# }

# resource "azurerm_subnet" "vng1-gwsubnet" {
#   name                 = "GatewaySubnet"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   virtual_network_name = azurerm_virtual_network.vnet2.name
#   address_prefixes     = ["10.2.3.0/24"]
# }

# resource "azurerm_virtual_network_gateway" "vng1" {
#   name                = "vng1"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   active_active       = true
#   type                = "Vpn"
#   vpn_type            = "RouteBased"
#   sku                 = "VpnGw1"

#   ip_configuration {
#     name                          = "vng1-ipconf1"
#     public_ip_address_id          = azurerm_public_ip.vng1-public-ip1.id
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.vng1-gwsubnet.id
#   }

#   ip_configuration {
#     name                          = "vng1-ipconf2"
#     public_ip_address_id          = azurerm_public_ip.vng1-public-ip2.id
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.vng1-gwsubnet.id
#   }  

#   bgp_settings {
#     asn       = 65010   
#   }
# }

module "vm3" {
  source               = "../vm_module"
  name                 = "vm3"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet2-sub1.id, azurerm_subnet.vnet2-sub2.id]
  second_nic_enabled   = true
}

# module "vm4" {
#   source               = "../vm_module"
#   name                 = "vm4"
#   resource_group_name  = azurerm_resource_group.rg-ne.name
#   location             = azurerm_resource_group.rg-ne.location
#   admin_username       = var.admin_username
#   admin_password       = var.admin_password
#   subnet_ids           = [azurerm_subnet.vnet2-sub1.id]
# }

resource "azurerm_virtual_network" "vnet3" {
  name                = "vnet3"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  address_space       = ["10.3.0.0/16"]
}

resource "azurerm_subnet" "vnet3-sub1" {
  name                 = "vnet3-sub1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet3.name
  address_prefixes     = ["10.3.0.0/24"]
}

# module "vm1" {
#   source               = "../vm_module"
#   name                 = "vm1"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   location             = azurerm_resource_group.rg-we.location
#   admin_username       = var.admin_username
#   admin_password       = var.admin_password
#   subnet_ids           = [azurerm_subnet.vnet3-sub1.id]
#   first_nic_public_ip  = "no"  
# }

module "vm2" {
  source               = "../vm_module"
  name                 = "vm2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet3-sub1.id]
}

# resource "azurerm_virtual_network" "vnet4" {
#   name                = "vnet4"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   address_space       = ["10.4.0.0/16"]
# }

# resource "azurerm_subnet" "vnet4-sub1" {
#   name                 = "vnet4-sub1"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   virtual_network_name = azurerm_virtual_network.vnet4.name
#   address_prefixes     = ["10.4.1.0/24"]
# }

# resource "azurerm_public_ip" "vng2-public-ip1" {
#   name                = "vng2-public-ip1"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   sku                 = "Standard"
#   allocation_method   = "Static"
# }

# resource "azurerm_public_ip" "vng2-public-ip2" {
#   name                = "vng2-public-ip2"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   sku                 = "Standard"
#   allocation_method   = "Static"
# }

# resource "azurerm_subnet" "vng2-gwsubnet" {
#   name                 = "GatewaySubnet"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   virtual_network_name = azurerm_virtual_network.vnet4.name
#   address_prefixes     = ["10.4.0.0/24"]
# }

# resource "azurerm_virtual_network_gateway" "vng2" {
#   name                = "vng2"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   active_active       = true
#   type                = "Vpn"
#   vpn_type            = "RouteBased"  
#   sku                 = "VpnGw1"

#   ip_configuration {
#     name                          = "vng2-ipconf1"
#     public_ip_address_id          = azurerm_public_ip.vng2-public-ip1.id
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.vng2-gwsubnet.id
#   }  

#   ip_configuration {
#     name                          = "vng2-ipconf2"
#     public_ip_address_id          = azurerm_public_ip.vng2-public-ip2.id
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.vng2-gwsubnet.id
#   }  

#   bgp_settings {
#     asn       = 65011  
#   }
# }

# module "vm5" {
#   source               = "../vm_module"
#   name                 = "vm5"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   location             = azurerm_resource_group.rg-we.location
#   admin_username       = var.admin_username
#   admin_password       = var.admin_password
#   subnet_ids           = [azurerm_subnet.vnet4-sub1.id]
# }

# module "vm6" {
#   source               = "../vm_module"
#   name                 = "vm6"
#   resource_group_name  = azurerm_resource_group.rg-we.name
#   location             = azurerm_resource_group.rg-we.location
#   admin_username       = var.admin_username
#   admin_password       = var.admin_password
#   subnet_ids           = [azurerm_subnet.vnet4-sub1.id]
#   first_nic_public_ip  = "no"  
# }

# resource "azurerm_virtual_network_gateway_connection" "vng1-vng2-connection" {
#   name                        = "vng1-vng2-connection"
#   location                    = azurerm_resource_group.rg-we.location
#   resource_group_name         = azurerm_resource_group.rg-we.name
#   virtual_network_gateway_id  = azurerm_virtual_network_gateway.vng1.id
#   peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng2.id  
#   shared_key                  = "Test123"
#   type                        = "Vnet2Vnet"
#   enable_bgp                  = true
#   use_policy_based_traffic_selectors = false
# }


# resource "azurerm_virtual_network_gateway_connection" "vng2-vng1-connection" {
#   name                        = "vng2-vng1-connection"
#   location                    = azurerm_resource_group.rg-we.location
#   resource_group_name         = azurerm_resource_group.rg-we.name
#   virtual_network_gateway_id  = azurerm_virtual_network_gateway.vng2.id
#   peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vng1.id  
#   shared_key                  = "Test123"
#   type                        = "Vnet2Vnet"
#   enable_bgp                  = true
#   use_policy_based_traffic_selectors = false
#   depends_on = [azurerm_virtual_network_gateway_connection.vng1-vng2-connection]
# }

# resource "azurerm_public_ip" "route-server-pip" {
#   name                = "route-server-pip"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   allocation_method   = "Static"
# }

# resource "azurerm_route_server" "route-server" {
#   name                = "route-server"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   virtual_network_id  = azurerm_virtual_network.vnet2.id
#   subnet_id           = azurerm_subnet.vnet2-sub3.id
#   public_ip_address_id = azurerm_public_ip.route-server-pip.id
# }





