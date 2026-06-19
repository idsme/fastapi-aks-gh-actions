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
  admin_enabled       = true                                       # Enable admin credentials so Docker CLI can authenticate using username and password
}

resource "azurerm_kubernetes_cluster" "fastapi_aks" {              # Create the AKS managed Kubernetes cluster to run application workloads
  name                = "fastapi-aks-cluster"                      # Name of the AKS cluster as it appears in Azure
  location            = azurerm_resource_group.fastapi_rg.location # Deploy the cluster in the same region as the resource group
  resource_group_name = azurerm_resource_group.fastapi_rg.name     # Place the cluster inside the project resource group
  dns_prefix          = "fastapi"                                  # DNS prefix used to build the cluster API server's public hostname

  default_node_pool {              # Define the primary pool of virtual machines that run the Kubernetes worker nodes
    name       = "default"         # Internal name of the default node pool
    node_count = 2                 # Provision two nodes to provide basic redundancy and workload distribution
    vm_size    = "Standard_DS2_v2" # VM size per node: 2 vCPUs and 7 GB RAM — balanced for small workloads
  }

  identity {                # Configure the managed identity used by the cluster to interact with Azure services
    type = "SystemAssigned" # Use a system-assigned managed identity automatically created and managed by Azure
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {                                           # Grant the AKS cluster permission to pull images from the ACR
  principal_id         = azurerm_kubernetes_cluster.fastapi_aks.kubelet_identity[0].object_id # The managed identity of the AKS node pool (kubelet) that pulls container images
  role_definition_name = "AcrPull"                                                            # Built-in Azure role that allows reading and pulling images from a container registry
  scope                = azurerm_container_registry.acr.id                                    # Limit this role assignment to only the project ACR resource
}
