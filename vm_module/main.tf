variable "name" {}
variable "resource_group_name" {}
variable "location" {}
variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}
variable "admin_username" {}
variable "admin_password" {}
variable "first_nic_public_ip" {
  description = "Set to 'no' to not associate a public IP with the first NIC"
  default     = "yes"
}
variable "second_nic_enabled" {
  description = "Enable the second NIC"
  default     = false
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.first_nic_public_ip == "yes" ? 1 : 0
  name                = "${var.name}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"  
}

resource "azurerm_network_interface" "nic1" {
  name                = "${var.name}-nic1"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    # name                          = "${var.name}-ipconfig1"
    name                          = "ipconfig1"
    subnet_id                     = element(var.subnet_ids, 0)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.first_nic_public_ip == "yes" ? azurerm_public_ip.public_ip[0].id : null
  }
}

resource "azurerm_network_interface" "nic2" {
  count               = var.second_nic_enabled ? 1 : 0
  name                = "${var.name}-nic2"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    # name                          = "${var.name}-ipconfig2"
    name                          = "ipconfig1"
    subnet_id                     = element(var.subnet_ids, 1)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  network_interface_ids        = concat(
    [azurerm_network_interface.nic1.id],
    var.second_nic_enabled ? [azurerm_network_interface.nic2[0].id] : []
  )
  primary_network_interface_id = azurerm_network_interface.nic1.id
  vm_size                      = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "nic_ids" {
  value = concat(
    [azurerm_network_interface.nic1.id],
    [for nic in azurerm_network_interface.nic2 : nic.id]
  )
}

