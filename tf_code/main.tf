# Create the Resource Groups



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




