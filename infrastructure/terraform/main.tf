

provider "azurerm" { 
  features {}  
  subscription_id = "6d9441a6-21a1-452d-afea-e162cd752430"  
}

resource "azurerm_resource_group" "fastapi_rg" {
  name     = "fastapi-resource-group"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "fastapiacr12345"  
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  location            = azurerm_resource_group.fastapi_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}



resource "azurerm_kubernetes_cluster" "fastapi_aks" {
  name                = "fastapi-aks-cluster"
  location            = azurerm_resource_group.fastapi_rg.location
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  dns_prefix          = "fastapi"

  default_node_pool {
    name       = "default"
    node_count = 2  
    vm_size    = "Standard_DS2_v2"  
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.fastapi_aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope               = azurerm_container_registry.acr.id
}





