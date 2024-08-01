data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "network_manager_rg" {
  location = var.primary-region
  name     = "network-manager-rg"
  }

resource "azurerm_network_manager" "network_manager_instance" {
  name                = "network-manager"
  location            = azurerm_resource_group.network_manager_rg.location
  resource_group_name = azurerm_resource_group.network_manager_rg.name
  scope_accesses      = ["Connectivity" , "SecurityAdmin"]
  description         = "example network manager"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

# Create a network group

resource "azurerm_network_manager_network_group" "primary-network_group" {
  name               = "primary-network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}

resource "azurerm_network_manager_network_group" "secondary-network_group" {
  name               = "secondary-network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}


resource "azurerm_network_manager_static_member" "primary-spoke" {
count = 2
  name                      = "spoke-primary-${count.index}"
  network_group_id          = azurerm_network_manager_network_group.primary-network_group.id
  target_virtual_network_id = azurerm_virtual_network.primary-spokes-vnet[count.index].id
}


resource "azurerm_network_manager_static_member" "secondary-spoke" {
count = 2
  name                      = "secondary-spoke-${count.index}"
  network_group_id          = azurerm_network_manager_network_group.secondary-network_group.id
  target_virtual_network_id = azurerm_virtual_network.secondary-spokes-vnet[count.index].id
}

# Create a connectivity configuration
resource "azurerm_network_manager_connectivity_configuration" "primary-hub-spoke" {
  name                  = "primary-hub-spoke-connectivity-conf"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "DirectlyConnected"
    network_group_id   = azurerm_network_manager_network_group.primary-network_group.id
  }

  hub {
    resource_id   = azurerm_virtual_network.primary-region-hub-vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

resource "azurerm_network_manager_connectivity_configuration" "secondary-hub-spoke" {
  name                  = "secondary-hub-spoke-connectivity-conf"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  applies_to_group {
    group_connectivity = "DirectlyConnected"
    network_group_id   = azurerm_network_manager_network_group.secondary-network_group.id
  }

  hub {
    resource_id   = azurerm_virtual_network.secondary-region-hub-vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

# Commit AVNM deployment

resource "azurerm_network_manager_deployment" "commit_deployment" {
  network_manager_id = azurerm_network_manager.network_manager_instance.id
  location           = azurerm_resource_group.network_manager_rg.location
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.primary-hub-spoke.id, azurerm_network_manager_connectivity_configuration.secondary-hub-spoke.id]
}
