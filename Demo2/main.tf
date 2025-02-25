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

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vnet1-sub1" {
  name                 = "vnet1-sub1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "vnet1-sub2" {
  name                 = "vnet1-sub2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "vnet1-sub3" {
  name                 = "vnet1-sub3"
  resource_group_name  = azurerm_resource_group.rg-we.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "vm1" {
  source               = "../vm_module"
  name                 = "vm1"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub3.id]
}

module "vm11" {
  source               = "../vm_module"
  name                 = "vm11"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub3.id]
  first_nic_public_ip  = "no"    
}

module "vm100" {
  source               = "../vm_module"
  name                 = "vm100"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub1.id, azurerm_subnet.vnet1-sub2.id]
  second_nic_enabled   = true
  }

output "vm100_nic_ids" {
    value = module.vm100.nic_ids
  }

module "vm101" {
  source               = "../vm_module"
  name                 = "vm101"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub1.id, azurerm_subnet.vnet1-sub2.id]
  second_nic_enabled   = true
}

output "vm101_nic_ids" {
    value = module.vm101.nic_ids
}

module "vm2" {
  source               = "../vm_module"
  name                 = "vm2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub1.id]  
}

# # Remove private IPs, only use after enabling health probe listener
# resource "null_resource" "update_vm100_nic1" {
#   provisioner "local-exec" {
#     command = "az network nic update --name vm100-nic1 --resource-group rg-we --remove ipConfigurations[0].publicIpAddress"
#   }
#   depends_on = [azurerm_lb.internal_lb]
# }

# resource "null_resource" "update_vm101_nic1" {
#   provisioner "local-exec" {
#     command = "az network nic update --name vm101-nic1 --resource-group rg-we --remove ipConfigurations[0].publicIpAddress"
#   }
#   depends_on = [azurerm_lb.internal_lb]
# }

module "vm3" {
  source               = "../vm_module"
  name                 = "vm3"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet1-sub2.id]  
}

locals {  
  vm100_nic_ids = module.vm100.nic_ids
  vm101_nic_ids = module.vm101.nic_ids
}

resource "azurerm_lb" "internal_lb" {
  name                = "internal-lb"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend-config"
    subnet_id                     = azurerm_subnet.vnet1-sub2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.100"
    zones                         = ["1", "2"] 
  }
}

# resource "azurerm_lb_backend_address_pool" "internal_lb_backend_pool" {
#   loadbalancer_id = azurerm_lb.internal_lb.id
#   name            = "internal-backend-pool"  
# }

# resource "azurerm_lb_probe" "internal_lb_probe" {
#   loadbalancer_id = azurerm_lb.internal_lb.id
#   name            = "internal-probe"
#   protocol        = "Tcp"
#   port            = 80
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "internal_lb_rule" {
#   loadbalancer_id                  = azurerm_lb.internal_lb.id
#   name                             = "internal-lb-rule"
#   protocol                         = "Tcp"
#   frontend_port                    = 80
#   backend_port                     = 80
#   frontend_ip_configuration_name   = azurerm_lb.internal_lb.frontend_ip_configuration[0].name
#   backend_address_pool_ids         = [azurerm_lb_backend_address_pool.internal_lb_backend_pool.id]
#   probe_id                         = azurerm_lb_probe.internal_lb_probe.id
# }

# resource "azurerm_network_interface_backend_address_pool_association" "nva1_backend_pool" {
#   network_interface_id        = local.vm100_nic_ids[1]
#   ip_configuration_name       = "ipconfig1"
#   backend_address_pool_id     = azurerm_lb_backend_address_pool.internal_lb_backend_pool.id
#   depends_on = [module.vm100]
# }

# resource "azurerm_network_interface_backend_address_pool_association" "nva2_backend_pool" {
#   network_interface_id        = local.vm101_nic_ids[1]
#   ip_configuration_name       = "ipconfig1"
#   backend_address_pool_id     = azurerm_lb_backend_address_pool.internal_lb_backend_pool.id
#   depends_on = [module.vm101]
# }

# resource "azurerm_lb" "external_lb" {
#   name                = "external-lb"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   sku = "Standard"

#   frontend_ip_configuration {
#     name                 = "frontend-config"
#     public_ip_address_id = azurerm_public_ip.external_ip.id
#     # zones                = ["1", "2"]
#   }
# }

# resource "azurerm_public_ip" "external_ip" {
#   name                = "external-ip"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1", "2"]
# }

# resource "azurerm_lb_probe" "external_lb_probe" {
#   loadbalancer_id = azurerm_lb.external_lb.id
#   name            = "external-probe"
#   protocol        = "Tcp"
#   port            = 8181
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "external_lb_rule" {
#   loadbalancer_id                = azurerm_lb.external_lb.id
#   name                           = "external-lb-rule"
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = 80
#   frontend_ip_configuration_name = azurerm_lb.external_lb.frontend_ip_configuration[0].name
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.external_lb_backend_pool.id]
#   probe_id                       = azurerm_lb_probe.external_lb_probe.id
# }

# resource "azurerm_network_interface_backend_address_pool_association" "nva1_frontend_pool" {
#   network_interface_id        = local.vm100_nic_ids[0]
#   ip_configuration_name       = "ipconfig1"
#   backend_address_pool_id     = azurerm_lb_backend_address_pool.external_lb_backend_pool.id
#   depends_on = [module.vm100]
# }

# resource "azurerm_network_interface_backend_address_pool_association" "nva2_frontend_pool" {
#   network_interface_id        = local.vm101_nic_ids[0]
#   ip_configuration_name       = "ipconfig1"
#   backend_address_pool_id     = azurerm_lb_backend_address_pool.external_lb_backend_pool.id
#   depends_on = [module.vm101]
# }


resource "azurerm_route_table" "rt-vnet1-sub3" {
  name                = "rt-vnet1-sub3"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
}

resource "azurerm_route" "route-to-ilb" {
  name                   = "route-to-ilb"
  resource_group_name    = azurerm_resource_group.rg-we.name
  route_table_name       = azurerm_route_table.rt-vnet1-sub3.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.1.100"
}

resource "azurerm_subnet_route_table_association" "vnet1-sub3-to-rt-vnet1-sub3-ass" {
  subnet_id      = azurerm_subnet.vnet1-sub3.id
  route_table_id = azurerm_route_table.rt-vnet1-sub3.id
}

# resource "azurerm_route_table" "rt-vnet1-sub1" {
#   name                = "rt-vnet1-sub1"
#   location            = azurerm_resource_group.rg-we.location
#   resource_group_name = azurerm_resource_group.rg-we.name
# }

# resource "azurerm_route" "route-to-elb" {
#   name                   = "route-to-elb"
#   resource_group_name    = azurerm_resource_group.rg-we.name
#   route_table_name       = azurerm_route_table.rt-vnet1-sub1.name
#   address_prefix         = "0.0.0.0/0"
#   next_hop_type          = "Internet"  
# }

# resource "azurerm_subnet_route_table_association" "vnet1-sub1-to-rt-vnet1-sub1-ass" {
#   subnet_id      = azurerm_subnet.vnet1-sub1.id
#   route_table_id = azurerm_route_table.rt-vnet1-sub1.id
# }
