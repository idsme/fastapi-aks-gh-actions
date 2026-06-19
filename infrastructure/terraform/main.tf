provider "azurerm" {                                       # Configure the Azure Resource Manager Terraform provider
  features {}                                              # Required block for azurerm; enables all default provider feature behaviors
  subscription_id = "9bef997e-4efe-4bae-9492-5719272bef52" # Azure subscription ID where all resources will be created
}

resource "azurerm_resource_group" "fastapi_rg" { # Create a resource group to logically contain all project resources
  name     = "fastapi-resource-group"            # Name of the resource group as it appears in Azure
  location = "East US"                           # Azure region where the resource group and its child resources are deployed
}

resource "azurerm_container_registry" "acr" {                      # Create an Azure Container Registry to store and serve Docker images
  name                = "fastapiacr12345"                          # Globally unique name for the registry (alphanumeric only, 5–50 chars)
  resource_group_name = azurerm_resource_group.fastapi_rg.name     # Place the ACR inside the project resource group
  location            = azurerm_resource_group.fastapi_rg.location # Deploy ACR in the same Azure region as the resource group
  sku                 = "Basic"                                    # Use the Basic SKU — lowest cost tier, sufficient for development workloads
  admin_enabled       = true                                       # Enable admin credentials so MedionK3s can pull images using an imagePullSecret
}

# NOTE: The Kubernetes cluster (MedionK3s) is pre-existing and not managed by Terraform.
# ACR pull access for MedionK3s is handled via a Kubernetes imagePullSecret (see deployment.yaml)
# rather than an Azure role assignment, since MedionK3s is a K3s cluster without an AKS managed identity.
