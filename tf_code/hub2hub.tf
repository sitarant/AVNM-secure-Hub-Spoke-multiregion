
#hub peerings
resource "azurerm_virtual_network_peering" "hub2hub" {
  name                         = "hub2hub"
  resource_group_name          = azurerm_resource_group.region1.name
  virtual_network_name         = azurerm_virtual_network.primary-region.name
  remote_virtual_network_id    = azurerm_virtual_network.secondary-region.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  
}

resource "azurerm_virtual_network_peering" "hub2hub2" {
  name                         = "hub2hub2"
  resource_group_name          = azurerm_resource_group.region2
  virtual_network_name         = azurerm_virtual_network.secondary-region.name
  remote_virtual_network_id    = azurerm_virtual_network.primary-region.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  
}