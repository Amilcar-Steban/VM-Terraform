
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
resource "azurerm_resource_group" "vm-deploy-arg" {
  name     = var.name_function
  location = var.location
  tags = {
    environment = "dev"
  }
}
resource "azurerm_virtual_network" "vm-deploy-avn" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.vm-deploy-arg.location
  resource_group_name = azurerm_resource_group.vm-deploy-arg.name
  address_space       = ["10.123.0.0/16"]
  tags = {
    environment = "dev"
  }
}
resource "azurerm_subnet" "vm-deploy-subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.vm-deploy-arg.name
  virtual_network_name = azurerm_virtual_network.vm-deploy-avn.name
  address_prefixes     = ["10.123.1.0/24"]
}
resource "azurerm_network_security_group" "vm-deploy-asg" {
  name                = "${var.prefix}-asg"
  location            = azurerm_resource_group.vm-deploy-arg.location
  resource_group_name = azurerm_resource_group.vm-deploy-arg.name

  tags = {
    environment = "dev"
  }
}
resource "azurerm_network_security_rule" "vm-deploy-rule" {
  name                        = "${var.prefix}-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vm-deploy-arg.name
  network_security_group_name = azurerm_network_security_group.vm-deploy-asg.name
}
resource "azurerm_subnet_network_security_group_association" "vm-deploy-asga" {
  subnet_id                 = azurerm_subnet.vm-deploy-subnet.id
  network_security_group_id = azurerm_network_security_group.vm-deploy-asg.id
}
resource "azurerm_public_ip" "vm-deploy-ip" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.vm-deploy-arg.name
  location            = azurerm_resource_group.vm-deploy-arg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}
resource "azurerm_network_interface" "vm-deploy-anic" {
  name                = "${var.prefix}-anic"
  location            = azurerm_resource_group.vm-deploy-arg.location
  resource_group_name = azurerm_resource_group.vm-deploy-arg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm-deploy-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-deploy-ip.id
  }

  tags = {
    environment = "dev"
  }
}
resource "azurerm_linux_virtual_machine" "vm-deploy-vm" {
  name                  = "mtc-vm"
  resource_group_name   = azurerm_resource_group.vm-deploy-arg.name
  location              = azurerm_resource_group.vm-deploy-arg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.vm-deploy-anic.id, ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/vm-deploy-key-ssh.pub.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  tags = {
    environment = "dev"
  }
}