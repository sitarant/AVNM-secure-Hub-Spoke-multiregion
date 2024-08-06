variable "primary-region" {
  type        = string
  description = "First region where resources will be deployed"
  default = "swedencentral"
}

variable "secondary-region" {
  type        = string
  description = "Secondary region where resources will be deployed"
  default = "norwayeast"
}


variable primary-rg {
  description = "Resource group for primary Azure region"
  type        = string
  default     = "AVNM-primary-rg"
}

variable secondary-rg {
  description = "Resource group for secondary Azure region"
  type        = string
  default     = "AVNM-secondary-rg"
}

variable "vm-user" {
    description = "Admin username for all VMs in the lab"
    type = string
    default = "azureuser"
}

variable "vm-password" {
    description = "Password for all VMs in the lab"
    type = string
    sensitive   = true
}

variable "vm-size" {
    description = "Azure VM size for all VMs in the lab"
    type = string
    default = "Standard_B1s"
}