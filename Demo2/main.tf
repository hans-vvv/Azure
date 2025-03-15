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

resource "azurerm_lb" "internal_lb" {
  name                = "internal-lb"
  location            = azurerm_resource_group.rg-we.location
  resource_group_name = azurerm_resource_group.rg-we.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend-config"
    subnet_id                     = azurerm_subnet.vnet1-sub2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.100"
    zones                         = ["1", "2"] 
  }
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
  first_nic_public_ip  = "no"
}

module "vm2" {
  source               = "../vm_module"
  name                 = "vm2"
  resource_group_name  = azurerm_resource_group.rg-we.name
  location             = azurerm_resource_group.rg-we.location
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  subnet_ids           = [azurerm_subnet.vnet2-sub1.id]  
}

resource "azurerm_virtual_network_peering" "vnet1-to-vnet2" {
  name                      = "vnet1-to-vnet2"
  resource_group_name       = azurerm_resource_group.rg-we.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network_peering" "vnet2-to-vnet1" {
  name                      = "vnet2-to-vnet1"
  resource_group_name       = azurerm_resource_group.rg-we.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  depends_on = [azurerm_virtual_network_peering.vnet1-to-vnet2]
}
