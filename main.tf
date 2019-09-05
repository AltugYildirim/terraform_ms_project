terraform {
 
required_version = ">= 0.11"
 
backend "azurerm" {
 
storage_account_name = "terrastateforms"
 
container_name       = "tfstatebackend"
 
key                  = "terraform.tfstate"
 
access_key           = "wiJ55aVUt++++SuDBi+YfYosJqteQWgWdRSWQHYltYXuR3DuuwWFo/sJCM6V4hAe/BB3eIOdcw0dXPliPiBPWQ=="
 
}
 
}
# Create a resource group if it doesn’t exist

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "altug_demo_terraform_rg_vm"
    location = "westeurope"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# # Create public IPs
# resource "azurerm_public_ip" "myterraformpublicip" {
#     name                         = "myPublicIP"
#     location                     = "westeurope"
#     resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
#     allocation_method            = "Dynamic"
    

#     tags = {
#         environment = "Terraform Demo"
#     }
# }

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    
    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "westeurope"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
#        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
        
    }
    

    tags = {
        environment = "Terraform Demo"
    }
}







# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "westeurope"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}
# data "azurerm_image" "custom" {
#   name                = "swoterraimage"
#   resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
# }

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "swoterratwo"
    location              = "westeurope"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    os_profile_windows_config {
        provision_vm_agent=true
        timezone="Romance Standard Time"
    }
#   storage_image_reference {
#     id = "${data.azurerm_image.custom.id}"
#   }

    storage_os_disk {
        name          = "myterravm-os"
        caching       = "ReadWrite"
        create_option = "FromImage"
        os_type       = "Windows"
#        create_option = "Attach"
    }

    storage_image_reference  {
        publisher="MicrosoftWindowsServer"
        offer="WindowsServer"
        sku="2019-Datacenter-with-Containers"
        version="latest"
    }
    
    os_profile {
        computer_name  = "swoterratwo"
        admin_username = "altug"
        admin_password = "${var.ARM_VAR_LocalSrvAccSecret}"
        
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo staging"
    }
}

# data "azurerm_public_ip" "test" {
#   name                = "${azurerm_public_ip.myterraformpublicip.name}"
#   resource_group_name = "${azurerm_virtual_machine.myterraformvm.resource_group_name}"
# }



resource "azurerm_virtual_machine_extension" "myterraformvm" {
    name            = "vmremotescript"
    location        = "West Europe"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_machine_name    = "${azurerm_virtual_machine.myterraformvm.name}"
    publisher       = "Microsoft.Compute"
    type            = "CustomScriptExtension"
    type_handler_version    = "1.9"

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/AltugYildirim/terraform_things/master/dockerpull.ps1"],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File dockerpull.ps1"
        
       
    }
SETTINGS
tags={
    environment = "Terraform Prod"
}
}
