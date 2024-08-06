#create hub networks and subnets in secondary regipon

resource "azurerm_virtual_network" "secondary-region" {
  name                = "secondary-region-vnet"
  resource_group_name = azurerm_resource_group.region2.name
  location            = azurerm_resource_group.region2.location
  address_space       = ["10.0.0.0/22"]

}

resource "azurerm_subnet" "secondary-region-hub-default" {
  name                 = "vm-subnet"
  virtual_network_name = azurerm_virtual_network.secondary-region.name
  resource_group_name  = azurerm_resource_group.region2.name
  address_prefixes     = ["10.0.0.0/24"]
  
}

resource "azurerm_subnet" "secondary-region-hub-firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.secondary-region.name
  resource_group_name  = azurerm_resource_group.region2.name
  address_prefixes     = ["10.0.1.0/24"]
  
}

resource "azurerm_subnet" "secondary-region-hub-gateway" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.secondary-region.name
  resource_group_name  = azurerm_resource_group.region2.name
  address_prefixes     = ["10.0.2.0/24"]
  
}

resource "azurerm_subnet" "secondary-region-hub-bastion" {
  name                 = "AzureBasionSubnet"
  virtual_network_name = azurerm_virtual_network.secondary-region.name
  resource_group_name  = azurerm_resource_group.region2.name
  address_prefixes     = ["10.0.3.0/24"]
  
}


#firewall deployments

resource "azurerm_public_ip" "secondary-firewall-pip" {
  name                = "secondary-fw-pip"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [1,2,3]
}


resource "azurerm_firewall" "secondary-firewall" {
  name                = "secondary-firewall"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones = [1,2,3]
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.secondary-region-hub-firewall.id
    public_ip_address_id = azurerm_public_ip.secondary-firewall-pip.id
  }
}

#create spokes

resource "azurerm_virtual_network" "secondary-spokes-vnet" {
  count = 2

  name                = "spoke-secondary-0${count.index}"
  resource_group_name = azurerm_resource_group.region2.name
  location            = azurerm_resource_group.region2.location
  address_space       = ["10.0.1${count.index}.0/24"]
}

resource "azurerm_subnet" "spoke-secondary-subnet-vm1" {
  count                = 2
  name                 = "vm1"
  virtual_network_name = azurerm_virtual_network.secondary-spokes-vnet[count.index].name
  resource_group_name  = azurerm_resource_group.region2.name
  address_prefixes     = ["10.0.1${count.index}.0/25"]
}

resource "azurerm_subnet" "spoke-secondary-subnet-vm2" {
  count                = 2
  name                 = "vm2"
  virtual_network_name = azurerm_virtual_network.secondary-spokes-vnet[count.index].name
  resource_group_name  = azurerm_resource_group.region2.name
  address_prefixes     = ["10.0.1${count.index}.128/25"]
}

#VPN Gateway deployment

resource "azurerm_public_ip" "secondary-vpn-gateway-pip" {
  name                = "secondary-vpn-gateway-pip"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  sku = "Standard"
  allocation_method = "Static"
}

resource "azurerm_virtual_network_gateway" "secondary-vpn-gateway" {
  name                = "secondaryvpn"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.secondary-vpn-gateway-pip.id
    subnet_id                     = azurerm_subnet.secondary-region-hub-gateway.id
  }
}



#VM deployment


# Secondary Hub VM
##############################
resource "azurerm_network_interface" "secondary-hub-vm-nic" {
  name                = "${var.secondary-region}-hub-vm-nic"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.secondary-region-hub-default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "secondary-hub-vm" {
  name                = "${var.secondary-region}-hub-vm"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.secondary-hub-vm-nic.id ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5"
    version   = "latest"
  }
}


##############################
# secondary Spoke1 VM1
##############################
resource "azurerm_network_interface" "secondary-spoke1-vm1-nic" {
  name                = "${var.secondary-region}-spoke1-vm1-nic"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-secondary-subnet-vm1[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "secondary-spoke1-vm1" {
  name                = "${var.secondary-region}-spoke1-vm1"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.secondary-spoke1-vm1-nic.id ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5"
    version   = "latest"
  }
}

##############################
# secondary Spoke1 VM2
##############################
resource "azurerm_network_interface" "secondary-spoke1-vm2-nic" {
  name                = "${var.secondary-region}-spoke1-vm2-nic"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-secondary-subnet-vm2[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "secondary-spoke1-vm2" {
  name                = "${var.secondary-region}-spoke1-vm2"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.secondary-spoke1-vm2-nic.id ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5"
    version   = "latest"
  }
}






##############################
# secondary Spoke2 VM1
##############################
resource "azurerm_network_interface" "secondary-spoke2-vm1-nic" {
  name                = "${var.secondary-region}-spoke2-vm1-nic"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-secondary-subnet-vm1[1].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "secondary-spoke2-vm1" {
  name                = "${var.secondary-region}-spoke2-vm1"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.secondary-spoke2-vm1-nic.id ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5"
    version   = "latest"
  }
}

##############################
# secondary Spoke2 VM2
##############################
resource "azurerm_network_interface" "secondary-spoke2-vm2-nic" {
  name                = "${var.secondary-region}-spoke2-vm2-nic"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-secondary-subnet-vm2[1].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "secondary-spoke2-vm2" {
  name                = "${var.secondary-region}-spoke2-vm2"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.secondary-spoke2-vm2-nic.id ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5"
    version   = "latest"
  }
}




