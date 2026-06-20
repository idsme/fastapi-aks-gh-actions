# ============================================================
# Arc-enabled MedionK3s cluster — current configuration
# Captured from: az connectedk8s show --name medionK3s --resource-group arcDemo
#
# IMPORTANT: This cluster already exists. Before running terraform apply,
# import the existing resources so Terraform does not try to recreate them:
#
#   terraform import azurerm_resource_group.arc_demo \
#     /subscriptions/9bef997e-4efe-4bae-9492-5719272bef52/resourceGroups/arcDemo
#
#   terraform import azurerm_arc_kubernetes_cluster.medion_k3s \
#     /subscriptions/9bef997e-4efe-4bae-9492-5719272bef52/resourceGroups/arcDemo/providers/Microsoft.Kubernetes/connectedClusters/medionK3s
#
# NOTE: Terraform manages the Azure-side Arc registration only.
# The physical K3s node and Arc agent running on MedionK3s are out of scope —
# those are installed via: az connectedk8s connect --name medionK3s --resource-group arcDemo
# ============================================================

resource "azurerm_resource_group" "arc_demo" {
  name     = "arcDemo"     # Name of the resource group that holds the Arc cluster registration
  location = "northeurope" # Azure region where the Arc registration resource lives (not the physical cluster location)
}

resource "azurerm_arc_kubernetes_cluster" "medion_k3s" {
  name                = "medionK3s"                              # Name of the Arc-connected cluster as it appears in Azure
  resource_group_name = azurerm_resource_group.arc_demo.name     # Resource group that owns this Arc registration
  location            = azurerm_resource_group.arc_demo.location # Must match the resource group location

  # Public key certificate of the Arc agent running on the physical MedionK3s node.
  # This is generated automatically when az connectedk8s connect is run and cannot
  # be changed here — update it only if the Arc agent is re-enrolled.
  agent_public_key_certificate = "MIICCgKCAgEAyk0Iv566xPezw65gUBmrby+dNMHR18FDQmkfKKWjrO4pRkgoI2nv/y9WtVghpKduhXQBW90ZiMLrbyhDX1gLSOyJTZFdSVMgCOT8U3vnsR6ynx/eZj+KZKYRi99cikQN6LGAblV9MOeoVzR/qDmP1jkqbGTEQiUAmOfyDY7LrS4mC4iz17DhKr0KJ+NHV7ocD1YNRc8oBgHCzeYiHX6EZA6aCPZHXd6UDQapDGj8wkYypDdGmUJsFsqDesd4D9qffyIaN5LJwlGCOQs1RCyWrM0YzbiT8dfOmMSGAqVf0xBUEJXni0rnFyA33RCKBU/JesD7DqI3eI1TSo18GkxK/aFCHKF2H8yojWvJxCBalhWb1IydmufnDN1oItXtFBH2P35OWVFCfLoIHvPolWey1+hLE3VlGKeJb4UnnklvsSVY/39OpepRyBpFKstAiRpwdCeERIwUTXHtcictLJ6ofI3p3j8maHu1k2NkiMd+qWAZN5LNr9JXkErlgP+Uad0qWfkiPS0/wb509y4J4LPHbH6qyyHVTMDsPh0DbfPuVnDEoPbhgmyokQ/jReSSRaIFeKJh5Lyc9cvxmE7bloWdG0waFHPa+UR/a6j/bUc3rXnFi7vZVwz7KCNuM58stLa8mkCfOT+BLrGqPyEeJolfOwafKj49VGQ4mAL1HfknMUsCAwEAAQ=="

  identity {
    type = "SystemAssigned" # Azure creates and manages the managed identity for this Arc registration automatically
  }

  tags = {
    "Datacenter City StateOrDistrict CountryOrRegion" = "" # Tag present on the cluster; value intentionally left blank
  }
}

# ============================================================
# Read-only reference outputs — useful for wiring other resources
# to this Arc cluster without hardcoding IDs.
# ============================================================

output "arc_cluster_id" {
  description = "Full Azure resource ID of the Arc-connected MedionK3s cluster"
  value       = azurerm_arc_kubernetes_cluster.medion_k3s.id
}

output "arc_cluster_identity_principal_id" {
  description = "Object ID of the system-assigned managed identity for the Arc cluster (eb2f3753-c092-4267-bcc2-0f8146155511)"
  value       = azurerm_arc_kubernetes_cluster.medion_k3s.identity[0].principal_id
}
