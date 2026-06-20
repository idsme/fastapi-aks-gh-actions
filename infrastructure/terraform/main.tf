provider "azurerm" {                                       # Configure the Azure Resource Manager Terraform provider
  features {}                                              # Required block for azurerm; enables all default provider feature behaviors
  subscription_id = "9bef997e-4efe-4bae-9492-5719272bef52" # Azure subscription ID where all resources will be created
}

# All infrastructure for this project lives in the arcDemo resource group (northeurope).
# See arc.tf for the resource group, Arc cluster, and container registry definitions.
