#create hub networks and subnets in primary regipon

resource "azurerm_virtual_network" "primary-region" {
  name                = "primary-region-vnet"
  resource_group_name = azurerm_resource_group.region1.name
  location            = azurerm_resource_group.region1.location
  address_space       = ["10.1.0.0/22"]

}

resource "azurerm_subnet" "primary-region-hub-default" {
  name                 = "vm-subnet"
  virtual_network_name = azurerm_virtual_network.primary-region.name
  resource_group_name  = azurerm_resource_group.region1.name
  address_prefixes     = ["10.1.0.0/24"]
  
}

resource "azurerm_subnet" "primary-region-hub-firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.primary-region.name
  resource_group_name  = azurerm_resource_group.region1.name
  address_prefixes     = ["10.1.1.0/24"]
  
}

resource "azurerm_subnet" "primary-region-hub-gateway" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.primary-region.name
  resource_group_name  = azurerm_resource_group.region1.name
  address_prefixes     = ["10.1.2.0/24"]
  
}

resource "azurerm_subnet" "primary-region-hub-bastion" {
  name                 = "AzureBasionSubnet"
  virtual_network_name = azurerm_virtual_network.primary-region.name
  resource_group_name  = azurerm_resource_group.region1.name
  address_prefixes     = ["10.1.3.0/24"]
  
}


#Firewall deployment

resource "azurerm_public_ip" "primary-firewall-pip" {
  name                = "primary-fw-pip"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [1,2,3]
}


resource "azurerm_firewall" "primary-firewall" {
  name                = "primary-firewall"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  zones = [1,2,3]
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.primary-region-hub-firewall.id
    public_ip_address_id = azurerm_public_ip.primary-firewall-pip.id
  }
}

#Create Spokes

resource "azurerm_virtual_network" "primary-spokes-vnet" {
  count = 2

  name                = "spoke-primary-0${count.index}"
  resource_group_name = azurerm_resource_group.region1.name
  location            = azurerm_resource_group.region1.location
  address_space       = ["10.1.1${count.index}.0/24"]
}


resource "azurerm_subnet" "spoke-primary-subnet-vm1" {
  count                = 2
  name                 = "vm1"
  virtual_network_name = azurerm_virtual_network.primary-spokes-vnet[count.index].name
  resource_group_name  = azurerm_resource_group.region1.name
  address_prefixes     = ["10.1.1${count.index}.0/25"]
  
}

resource "azurerm_subnet" "spoke-primary-subnet-vm2" {
  count                = 2
  name                 = "vm2"
  virtual_network_name = azurerm_virtual_network.primary-spokes-vnet[count.index].name
  resource_group_name  = azurerm_resource_group.region1.name
  address_prefixes     = ["10.1.1${count.index}.128/25"]
  
}

#vpn gateway deployment


resource "azurerm_public_ip" "primary-vpn-gateway-pip" {
  name                = "primary-vpn-gateway-pip"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "primary-vpn-gateway" {
  name                = "primaryvpn"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.primary-vpn-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.primary-region-hub-gateway.id
  }
}

#VM deployment


# Primary Hub VM
##############################
resource "azurerm_network_interface" "primary-hub-vm-nic" {
  name                = "${var.primary-region}-hub-vm-nic"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.primary-region-hub-default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "primary-hub-vm" {
  name                = "${var.primary-region}-hub-vm"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.primary-hub-vm-nic.id ]

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
# Primary Spoke1 VM1
##############################
resource "azurerm_network_interface" "primary-spoke1-vm1-nic" {
  name                = "${var.primary-region}-spoke1-vm1-nic"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-primary-subnet-vm1[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "primary-spoke1-vm1" {
  name                = "${var.primary-region}-spoke1-vm1"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.primary-spoke1-vm1-nic.id ]

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
# Primary Spoke1 VM2
##############################
resource "azurerm_network_interface" "primary-spoke1-vm2-nic" {
  name                = "${var.primary-region}-spoke1-vm2-nic"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-primary-subnet-vm2[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "primary-spoke1-vm2" {
  name                = "${var.primary-region}-spoke1-vm2"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.primary-spoke1-vm2-nic.id ]

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
# Primary Spoke2 VM1
##############################
resource "azurerm_network_interface" "primary-spoke2-vm1-nic" {
  name                = "${var.primary-region}-spoke2-vm1-nic"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-primary-subnet-vm1[1].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "primary-spoke2-vm1" {
  name                = "${var.primary-region}-spoke2-vm1"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.primary-spoke2-vm1-nic.id ]

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
# Primary Spoke2 VM2
##############################
resource "azurerm_network_interface" "primary-spoke2-vm2-nic" {
  name                = "${var.primary-region}-spoke2-vm2-nic"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke-primary-subnet-vm2[1].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "primary-spoke2-vm2" {
  name                = "${var.primary-region}-spoke2-vm2"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  size                = var.vm-size
  
  admin_username      = var.vm-user
  admin_password      = var.vm-password
  disable_password_authentication = false

  network_interface_ids = [ azurerm_network_interface.primary-spoke2-vm2-nic.id ]

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




