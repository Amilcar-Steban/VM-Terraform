# <p align="center"><strong>VIRTUAL MACHINE TERRAFORM</strong></p>


## Autors
*   Amilcar Rodriguez - A00369769

## Description

This project aims to create a virtual machine in azure using terraform, for this we will create different modules or configurations for the virtual machine to work correctly. 

## Step 1
Create main.tf, this file contain different components that are necesary to create the group and modules, for example:
* Virtual Network
* subnet, ip pública
* interfaz de red
* grupo de seguridad
* Asociacion IR-GS
* Virtual machine

### Virtual Network:

    resource "azurerm_virtual_network" "vm-deploy-avn" {
    name                = "${var.prefix}-network"
    location            = azurerm_resource_group.vm-deploy-arg.location
    resource_group_name = azurerm_resource_group.vm-deploy-arg.name
    address_space       = ["10.123.0.0/16"]
    tags = {
        environment = "dev"
        }
    }
### Subnet
    resource "azurerm_subnet" "vm-deploy-subnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = azurerm_resource_group.vm-deploy-arg.name
    virtual_network_name = azurerm_virtual_network.vm-deploy-avn.name
    address_prefixes     = ["10.123.1.0/24"]
    }
### Network security group
    resource "azurerm_network_security_group" "vm-deploy-asg" {
    name                = "${var.prefix}-asg"
    location            = azurerm_resource_group.vm-deploy-arg.location
    resource_group_name = azurerm_resource_group.vm-deploy-arg.name

    tags = {
        environment = "dev"
        }
    }
### Rules of network security 
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
### Subnet network security group
    resource "azurerm_subnet_network_security_group_association" "vm-deploy-asga" {
    subnet_id                 = azurerm_subnet.vm-deploy-subnet.id
    network_security_group_id = azurerm_network_security_group.vm-deploy-asg.id
    }
### ip public
    resource "azurerm_public_ip" "vm-deploy-ip" {
    name                = "${var.prefix}-ip"
    resource_group_name = azurerm_resource_group.vm-deploy-arg.name
    location            = azurerm_resource_group.vm-deploy-arg.location
    allocation_method   = "Dynamic"

    tags = {
        environment = "dev"
        }
    }
### Network interface
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
### Configuration virtual machine with ssh config
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

In the main we declared diferents varables, and this variables should be in a different file. We will create a file "variables.tf" and write the variables. So:

    variable "prefix" {
    type        = string
    description = "Prefix for resource names"
    }

    variable "name_function" {
    type        = string
    description = "Name of the function"
    }

    variable "location" {
    type        = string
    description = "Location for the Azure resources"
    }
And to put explicit values in the variables, we will create other file "terraform.tfvars" and modify as we wish

    name_function = "vm-deploy"
    location      = "East US"
    prefix        = "vm"

Also, we will create a file "providers.tf" and we specific the provider that is azurerm, so:

    provider "azurerm" {
    features {}
    }

## Step 2

Now, we will use this commands to up terraform main:

Login in azure:

    az login 
Init Terraform:

    terraform init

<p align="left">
  <img src="images/imagen1.png" alt="Image 1">
</p

Also, we should create the key to can connect ssh to vm. For this, we will use this command:

In the path, we select the path that we put in main.tf, in this case:

    admin_ssh_key {
        username   = "adminuser"
        public_key = file("~/.ssh/vm-deploy-key-ssh.pub.pub")
    }

    ssh-keygen -t rsa

When the file is create in the path, we ready to key for connect ssh.

## Step 3

Up the terraform, for this, we put this commands:

    terraform plan --var-file terraform.tfvars

And it should look like of this way:

<p align="left">
  <img src="images/Imagen2.png" alt="Image 2">
</p

Now, put the command to apply changes and up the configurations to azure:

    terraform apply -auto-approve

And it should look like of this way:

<p align="left">
  <img src="images/Imagen3.png" alt="Image 3">
</p

Confirm in the browser if the group and differents modules is create correctly, it should look like this:

<p align="left">
  <img src="images/Imagen5.png" alt="Image 5">
</p

<p align="left">
  <img src="images/Imagen6.png" alt="Image 6">
</p

## Step 4

Now, copy the ip public to virtual machine create in the step 3, and put this command since cmd to connect to machine to ssh:

    ssh -i ~/.ssh/vm-deploy-key-ssh.pub adminuser@13.92.140.210

And it should look like of this way:

<p align="left">
  <img src="images/Imagen4.png" alt="Image 4">
</p