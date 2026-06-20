# Application Landscape — FastAPI on MedionK3s (Arc-enabled)

## Full Landscape Diagram

```mermaid
graph TB
    DEV(["👤 Developer\nLocal machine"])
    USER(["🌐 End User"])

    subgraph GITHUB ["GitHub — github.com/idsme/fastapi-aks-gh-actions"]
        REPO["📦 Repository\nSource code · Dockerfile\nK8s manifests · Workflow"]
        ACTIONS["⚙️ GitHub Actions Runner\nubuntu-latest\nCI/CD pipeline"]
        SECRETS[("🔐 GitHub Secrets\nAZURE_CREDENTIALS")]
    end

    subgraph AZURE ["☁️ Azure  —  Subscription: 9bef997e"]
        ENTRA["🪪 Azure Entra ID\nService Principal\nfastapi-github-actions\n(Contributor + Arc Cluster User)"]
        subgraph RG ["📁 Resource Group: arcDemo  (northeurope)"]
            ACR["📦 Azure Container Registry\nacrakstraineeidsme.azurecr.io\nSKU: Basic · Admin enabled"]
            ARC_HUB["🔗 Azure Arc\nCluster Hub\nmedionK3s registration"]
        end
    end

    subgraph K3S ["🖥️ MedionK3s  —  Arc-enabled K3s  (192.168.178.70, Ubuntu 24.04)"]
        ARC_AGENT["Azure Arc Agent\nazure-arc namespace\n12 agent pods · 55d running"]
        subgraph K8S_NS ["default namespace"]
            K8S_SECRET["🔑 Secret: acr-secret\nACR pull credentials\n(one-time manual setup)"]
            K8S_DEPLOY["📋 Deployment: fastapi-app\n2 replicas · imagePullPolicy: Always"]
            K8S_SVC["⚖️ Service: fastapi-service\ntype: LoadBalancer\nexternal :80 → container :8000"]
            POD1["🐳 Pod\nfastapi-app\nuvicorn on :8000"]
            POD2["🐳 Pod\nfastapi-app\nuvicorn on :8000"]
        end
    end

    DEV -- "git push main" --> REPO
    DEV -- "terraform apply\n(one-time, done)" --> RG
    DEV -- "kubectl create secret\n(one-time)" --> K8S_SECRET
    REPO -- "on: push main" --> ACTIONS
    ACTIONS -- "reads" --> SECRETS
    SECRETS -. "AZURE_CREDENTIALS" .-> ENTRA
    ENTRA -- "auth token" --> ACTIONS
    ACTIONS -- "docker build + push" --> ACR
    ACTIONS -- "azure/k8s-set-context\nmethod: arc" --> ARC_HUB
    ARC_HUB -- "Arc tunnel" --> ARC_AGENT
    ARC_AGENT -- "proxies kubectl" --> K8S_DEPLOY
    K8S_DEPLOY -- "manages" --> POD1
    K8S_DEPLOY -- "manages" --> POD2
    K8S_SECRET -. "imagePullSecret" .-> POD1
    K8S_SECRET -. "imagePullSecret" .-> POD2
    POD1 -- "pull image" --> ACR
    POD2 -- "pull image" --> ACR
    K8S_SVC -- "routes traffic" --> POD1
    K8S_SVC -- "routes traffic" --> POD2
    USER -- "HTTP :80" --> K8S_SVC
    ARC_AGENT <-- "Arc connection\nHTTPS outbound" --> ARC_HUB
```

---

## What Is Configured in Azure (Resource Group: arcDemo, northeurope)

| Component | Resource | Status |
|---|---|---|
| **Azure Entra ID** | Service Principal `fastapi-github-actions` | ✅ Active — Contributor + Arc Cluster User Role |
| **GitHub Secret** | `AZURE_CREDENTIALS` | ✅ Configured |
| **Container Registry** | `acrakstraineeidsme.azurecr.io` — Basic SKU | ✅ Provisioned (Terraform managed) |
| **Azure Arc** | `medionK3s` cluster registration | ✅ Connected — K3s v1.34.6, 1 node |

> **To re-provision from scratch:**
> ```bash
> cd infrastructure/terraform
> terraform import azurerm_resource_group.arc_demo .../resourceGroups/arcDemo
> terraform import azurerm_arc_kubernetes_cluster.medion_k3s .../connectedClusters/medionK3s
> terraform import azurerm_container_registry.acr .../registries/acrakstraineeidsme
> terraform apply
> ```

---

## What Is Deployed to MedionK3s (192.168.178.70)

| Component | Kind | How it lands |
|---|---|---|
| **Azure Arc Agent** | 12 pods in `azure-arc` ns | Pre-existing — installed via `az connectedk8s connect` |
| **`acr-secret`** | Kubernetes Secret | `kubectl create secret docker-registry` (one-time) |
| **`fastapi-app`** | Deployment (2 pods) | GitHub Actions on every push to `main` |
| **`fastapi-service`** | Service (LoadBalancer) | Applied once via `kubectl apply` or `scripts/deploy.sh` |

> **One-time setup — create ACR pull secret on MedionK3s:**
> ```bash
> ACR_PASSWORD=$(az acr credential show --name acrakstraineeidsme --query passwords[0].value -o tsv)
> kubectl create secret docker-registry acr-secret \
>   --docker-server=acrakstraineeidsme.azurecr.io \
>   --docker-username=acrakstraineeidsme \
>   --docker-password=$ACR_PASSWORD
> ```

---

## Kubernetes RBAC (Arc identity → K3s)

| ClusterRoleBinding | Azure Object ID | Purpose |
|---|---|---|
| `arc-user-admin` | `e1fe12dd-...` | Owner account Arc proxy access |
| `fastapi-sp-admin` | `bdbfc8ac-...` | GitHub Actions SP deployment access |

---

## CI/CD Flow (every push to `main`)

```
Developer → git push main
    → GitHub Actions triggers
        → azure/login (AZURE_CREDENTIALS)
        → docker build
        → docker push → acrakstraineeidsme.azurecr.io
        → azure/k8s-set-context (method: arc, cluster: medionK3s)
            → Arc tunnel → MedionK3s (192.168.178.70)
                → kubectl set image deployment/fastapi-app
                → kubectl rollout restart
                → kubectl rollout status  ← blocks until healthy
```
