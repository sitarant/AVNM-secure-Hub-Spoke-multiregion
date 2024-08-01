# Create the Resource Group



resource "azurerm_resource_group" "global" {
  location = var.primary-region
  name     = "Global-RG"
  }

resource "azurerm_resource_group" "region1" {
  location = var.primary-region
  name     = var.primary-rg
  }

resource "azurerm_resource_group" "region2" {
  location =var.secondary-region
  name     = var.secondary-rg
  }




#vm deployment west us2

resource "azurerm_network_interface" "wus2-spoke-nic"{
    count               = 2
    name                = "wus2-spoke-nic-${count.index}"
    location            = azurerm_resource_group.region1.location
    resource_group_name = azurerm_resource_group.region1.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.spokewus2[count.index].id
        private_ip_address_allocation = "Dynamic"
    }
    
}

resource "azurerm_windows_virtual_machine" "vm-wus2-spoke" {
  count                = 2
  name                 = "vm-wus2-s-${count.index}"
  resource_group_name  = azurerm_resource_group.region1.name
  location             = azurerm_resource_group.region1.location
  size                 = "Standard_DS1_v2"
  admin_username       = "adminuser"
  admin_password       = "Password1234!"
  network_interface_ids = [azurerm_network_interface.wus2-spoke-nic[count.index].id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
}

#vm deployment east us

resource "azurerm_network_interface" "subneteus" {
    count               = 2
    name                = "eus-spoke-nic-${count.index}"
    location            = azurerm_resource_group.region2.location
    resource_group_name = azurerm_resource_group.region2.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.subneteus[count.index].id
        private_ip_address_allocation = "Dynamic"
    }
}
resource "azurerm_windows_virtual_machine" "vm_spoke_eus" {
    count                = 2
    name                 = "vm-eus-s-${count.index}"
    resource_group_name  = azurerm_resource_group.region2.name
    location             = azurerm_resource_group.region2.location
    size                 = "Standard_DS1_v2"
    admin_username       = "adminuser"
    admin_password       = "Password1234!"
    network_interface_ids = [azurerm_network_interface.subneteus[count.index].id]
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }
}

#hub vm deployment

resource "azurerm_network_interface" "wus2-hub-nic" {
    name                = "wus2-hub-nic"
    location            = azurerm_resource_group.region1.location
    resource_group_name = azurerm_resource_group.region1.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.wus2-hub-default.id
        private_ip_address_allocation = "Dynamic"
    }  
}
resource "azurerm_windows_virtual_machine" "hub-wus2" {
    name                = "hub-wus2"
    resource_group_name = azurerm_resource_group.region1.name
    location            = azurerm_resource_group.region1.location
    size                = "Standard_DS1_v2"
    admin_username      = "adminuser"
    admin_password      = "Password1234!"
    network_interface_ids = [azurerm_network_interface.wus2-hub-nic.id]
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }
}


resource "azurerm_network_interface" "eus-hub-nic" {
    name                = "eus-hub-nic"
    location            = azurerm_resource_group.region2.location
    resource_group_name = azurerm_resource_group.region2.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.eus-hub-default.id
        private_ip_address_allocation = "Dynamic"
    }  
}

resource "azurerm_windows_virtual_machine" "hub-eus" {
    name                = "hub-eus"
    resource_group_name = azurerm_resource_group.region2.name
    location            = azurerm_resource_group.region2.location
    size                = "Standard_DS1_v2"
    admin_username      = "adminuser"
    admin_password      = "Password1234!"
    network_interface_ids = [azurerm_network_interface.eus-hub-nic.id]
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }
}