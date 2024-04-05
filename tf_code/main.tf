# Create the Resource Group



resource "azurerm_resource_group" "rgwus2" {
  location = "west us2"
  name     = "rg-west-us2"
  }

resource "azurerm_resource_group" "rgeus" {
  location = "east us"
  name     = "rg-east-us"
  }

#create hub networks and subnets

resource "azurerm_virtual_network" "wus2-hub-vnet" {
  name                = "wus2-hub-vnet"
  resource_group_name = azurerm_resource_group.rgwus2.name
  location            = azurerm_resource_group.rgwus2.location
  address_space       = ["10.1.0.0/22"]

}

resource "azurerm_subnet" "wus2-hub-default" {
  name                 = "Default"
  virtual_network_name = azurerm_virtual_network.wus2-hub-vnet.name
  resource_group_name  = azurerm_resource_group.rgwus2.name
  address_prefixes     = ["10.1.0.0/24"]
  
}

resource "azurerm_subnet" "wus2-hub-firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.wus2-hub-vnet.name
  resource_group_name  = azurerm_resource_group.rgwus2.name
  address_prefixes     = ["10.1.1.0/24"]
  
}


resource "azurerm_virtual_network" "eus-hub-vnet" {
  name                = "eus-hub-vnet"
  resource_group_name = azurerm_resource_group.rgeus.name
  location            = azurerm_resource_group.rgeus.location
  address_space       = ["10.0.0.0/22"]
}

resource "azurerm_subnet" "eus-hub-default" {
  name                 = "Default"
  virtual_network_name = azurerm_virtual_network.eus-hub-vnet.name
  resource_group_name  = azurerm_resource_group.rgeus.name
  address_prefixes     = ["10.0.0.0/24"]
  
}

resource "azurerm_subnet" "eus-hub-firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.eus-hub-vnet.name
  resource_group_name  = azurerm_resource_group.rgeus.name
  address_prefixes     = ["10.0.1.0/24"]    
}

#hub peerings
resource "azurerm_virtual_network_peering" "hub2hub" {
  name                         = "hub2hub"
  resource_group_name          = azurerm_resource_group.rgwus2.name
  virtual_network_name         = azurerm_virtual_network.wus2-hub-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.eus-hub-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  
}

resource "azurerm_virtual_network_peering" "hub2hub2" {
  name                         = "hub2hub2"
  resource_group_name          = azurerm_resource_group.rgeus.name
  virtual_network_name         = azurerm_virtual_network.eus-hub-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.wus2-hub-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  
}


#Deploy Azure Firewalls missing azure policy, need to be created: one parent, two child policies (per region)

resource "azurerm_public_ip" "wus2-firewall-pip" {
  name                = "wus2-fw-pip"
  location            = azurerm_resource_group.rgwus2.location
  resource_group_name = azurerm_resource_group.rgwus2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [1,2,3]
}


resource "azurerm_firewall" "wus2-firewall" {
  name                = "wus2-firewall"
  location            = azurerm_resource_group.rgwus2.location
  resource_group_name = azurerm_resource_group.rgwus2.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones = [1,2,3]
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.wus2-hub-firewall.id
    public_ip_address_id = azurerm_public_ip.wus2-firewall-pip.id
  }
}


resource "azurerm_public_ip" "eus-firewall-pip" {
  name                = "eus-fw-pip"
  location            = azurerm_resource_group.rgeus.location
  resource_group_name = azurerm_resource_group.rgeus.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [1,2,3]
}


resource "azurerm_firewall" "eus-firewall" {
  name                = "eus-firewall"
  location            = azurerm_resource_group.rgeus.location
  resource_group_name = azurerm_resource_group.rgeus.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones = [1,2,3]
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.eus-hub-firewall.id
    public_ip_address_id = azurerm_public_ip.eus-firewall-pip.id
  }
}

#Create spoke networks 

# resource "random_string" "prefix" {
#   length = 4
#   special = false
#   upper = false
# }

# resource "random_pet" "wus2-virtual_network_name" {
#   prefix = "vnet-wus2-${random_string.prefix.result}"
# }

# resource "random_pet" "eus-virtual_network_name" {
#   prefix = "vnet-eus-${random_string.prefix.result}"
# }


resource "azurerm_virtual_network" "wus2-vnet" {
  count = 2

  name                = "vnet-wus2-0${count.index}"
  resource_group_name = azurerm_resource_group.rgwus2.name
  location            = azurerm_resource_group.rgwus2.location
  address_space       = ["10.1.1${count.index}.0/24"]
}

resource "azurerm_subnet" "spokewus2" {
  count                = 2
  name                 = "Default"
  virtual_network_name = azurerm_virtual_network.wus2-vnet[count.index].name
  resource_group_name  = azurerm_resource_group.rgwus2.name
  address_prefixes     = ["10.1.1${count.index}.0/24"]
  
}
resource "azurerm_virtual_network" "eus-vnet" {
  count = 2

  name                = "vnet-eus-0${count.index}"
  resource_group_name = azurerm_resource_group.rgeus.name
  location            = azurerm_resource_group.rgeus.location
  address_space       = ["10.0.1${count.index}.0/24"]
}

resource "azurerm_subnet" "subneteus" {
  count                = 2
  name                 = "Default"
  virtual_network_name = azurerm_virtual_network.eus-vnet[count.index].name
  resource_group_name  = azurerm_resource_group.rgeus.name
  address_prefixes     = ["10.0.1${count.index}.0/24"]
  
}

# Create a Virtual Network Manager instance

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "network_manager_rg" {
  location = "west us2"
  name     = "network-manager-rg"
  }

resource "azurerm_network_manager" "network_manager_instance" {
  name                = "network-manager"
  location            = azurerm_resource_group.network_manager_rg.location
  resource_group_name = azurerm_resource_group.network_manager_rg.name
  scope_accesses      = ["Connectivity"]
  description         = "example network manager"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

# Create a network group

resource "azurerm_network_manager_network_group" "wus2-network_group" {
  name               = "wus2-network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}

resource "azurerm_network_manager_network_group" "eus-network_group" {
  name               = "eus-network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}


resource "azurerm_network_manager_static_member" "wus2-spoke" {
count = 2
  name                      = "wus2-spoke-${count.index}"
  network_group_id          = azurerm_network_manager_network_group.wus2-network_group.id
  target_virtual_network_id = azurerm_virtual_network.wus2-vnet[count.index].id
}


resource "azurerm_network_manager_static_member" "eus-spoke" {
count = 2
  name                      = "eus2-spoke-${count.index}"
  network_group_id          = azurerm_network_manager_network_group.eus-network_group.id
  target_virtual_network_id = azurerm_virtual_network.eus-vnet[count.index].id
}

# Create a connectivity configuration
resource "azurerm_network_manager_connectivity_configuration" "wus2-hub-spoke" {
  name                  = "wus2-hub-spoke-connectivity-conf"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "DirectlyConnected"
    network_group_id   = azurerm_network_manager_network_group.wus2-network_group.id
  }

  hub {
    resource_id   = azurerm_virtual_network.wus2-hub-vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

resource "azurerm_network_manager_connectivity_configuration" "eus-hub-spoke" {
  name                  = "eus-hub-spoke-connectivity-conf"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "DirectlyConnected"
    network_group_id   = azurerm_network_manager_network_group.eus-network_group.id
  }

  hub {
    resource_id   = azurerm_virtual_network.eus-hub-vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

# Commit AVNM deployment

resource "azurerm_network_manager_deployment" "commit_deployment" {
  network_manager_id = azurerm_network_manager.network_manager_instance.id
  location           = azurerm_resource_group.network_manager_rg.location
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.wus2-hub-spoke.id, azurerm_network_manager_connectivity_configuration.eus-hub-spoke.id]
}



#vm deployment west us2

resource "azurerm_network_interface" "wus2-spoke-nic"{
    count               = 2
    name                = "wus2-spoke-nic-${count.index}"
    location            = azurerm_resource_group.rgwus2.location
    resource_group_name = azurerm_resource_group.rgwus2.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.spokewus2[count.index].id
        private_ip_address_allocation = "Dynamic"
    }
    
}

resource "azurerm_windows_virtual_machine" "vm-wus2-spoke" {
  count                = 2
  name                 = "vm-wus2-s-${count.index}"
  resource_group_name  = azurerm_resource_group.rgwus2.name
  location             = azurerm_resource_group.rgwus2.location
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
    location            = azurerm_resource_group.rgeus.location
    resource_group_name = azurerm_resource_group.rgeus.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.subneteus[count.index].id
        private_ip_address_allocation = "Dynamic"
    }
}
resource "azurerm_windows_virtual_machine" "vm_spoke_eus" {
    count                = 2
    name                 = "vm-eus-s-${count.index}"
    resource_group_name  = azurerm_resource_group.rgeus.name
    location             = azurerm_resource_group.rgeus.location
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
    location            = azurerm_resource_group.rgwus2.location
    resource_group_name = azurerm_resource_group.rgwus2.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.wus2-hub-default.id
        private_ip_address_allocation = "Dynamic"
    }  
}
resource "azurerm_windows_virtual_machine" "hub-wus2" {
    name                = "hub-wus2"
    resource_group_name = azurerm_resource_group.rgwus2.name
    location            = azurerm_resource_group.rgwus2.location
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
    location            = azurerm_resource_group.rgeus.location
    resource_group_name = azurerm_resource_group.rgeus.name
    
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.eus-hub-default.id
        private_ip_address_allocation = "Dynamic"
    }  
}

resource "azurerm_windows_virtual_machine" "hub-eus" {
    name                = "hub-eus"
    resource_group_name = azurerm_resource_group.rgeus.name
    location            = azurerm_resource_group.rgeus.location
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