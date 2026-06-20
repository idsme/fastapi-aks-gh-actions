# Application Landscape — FastAPI on MedionK3s (Arc-enabled)

## Full Landscape Diagram

```mermaid
graph TB
    DEV(["👤 Developer\nLocal machine"])
    USER(["🌐 End User"])

    subgraph GITHUB ["GitHub — github.com/idsme/fastapi-aks-gh-actions"]
        REPO["📦 Repository\nSource code · Dockerfile\nK8s manifests · Workflow"]
        ACTIONS["⚙️ GitHub Actions Runner\nubuntu-latest\nCI/CD pipeline"]
        SECRETS[("🔐 GitHub Secrets\nAZURE_CREDENTIALS\nKUBE_CONFIG")]
    end

    subgraph AZURE ["☁️ Azure  —  Subscription: 9bef997e"]
        ENTRA["🪪 Azure Entra ID\nService Principal\nfastapi-github-actions\n(Contributor role)"]
        subgraph RG ["📁 Resource Group: fastapi-resource-group  (East US)"]
            ACR["📦 Azure Container Registry\nfastapiacr12345.azurecr.io\nSKU: Basic · Admin enabled"]
        end
        ARC_HUB["🔗 Azure Arc\nCluster Hub\n(cluster management & monitoring)"]
    end

    subgraph K3S ["🖥️ MedionK3s  —  Arc-enabled K3s Cluster  (on-premise)"]
        ARC_AGENT["Azure Arc Agent\nazure-arc namespace\nPhones home to Azure Arc Hub"]
        subgraph K8S_NS ["default namespace"]
            K8S_SECRET["🔑 Secret: acr-secret\nACR pull credentials\n(one-time manual setup)"]
            K8S_DEPLOY["📋 Deployment: fastapi-app\n2 replicas · imagePullPolicy: Always"]
            K8S_SVC["⚖️ Service: fastapi-service\ntype: LoadBalancer\nexternal :80 → container :8000"]
            POD1["🐳 Pod\nfastapi-app-xxx\nuvicorn on :8000"]
            POD2["🐳 Pod\nfastapi-app-yyy\nuvicorn on :8000"]
        end
    end

    DEV -- "git push main" --> REPO
    DEV -- "terraform apply\n(one-time)" --> RG
    DEV -- "kubectl create secret\n(one-time)" --> K8S_SECRET
    REPO -- "on: push main" --> ACTIONS
    ACTIONS -- "reads" --> SECRETS
    SECRETS -. "AZURE_CREDENTIALS" .-> ENTRA
    ENTRA -- "auth token" --> ACTIONS
    ACTIONS -- "docker build + push" --> ACR
    SECRETS -. "KUBE_CONFIG\n(base64 kubeconfig)" .-> ACTIONS
    ACTIONS -- "kubectl set image\nkubectl rollout restart" --> K8S_DEPLOY
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

## What Must Be Configured in Azure

| Component | How | Status |
|---|---|---|
| **Azure Entra ID — Service Principal** (`fastapi-github-actions`) | `az ad sp create-for-rbac` | ✅ Done |
| **GitHub Secret** `AZURE_CREDENTIALS` | `gh secret set` | ✅ Done |
| **Resource Group** (`fastapi-resource-group`, East US) | `terraform apply` | ⏳ Pending |
| **Azure Container Registry** (`fastapiacr12345.azurecr.io`) | `terraform apply` | ⏳ Pending |
| **Azure Arc** — register MedionK3s as Arc-enabled cluster | Azure Portal or `az connectedk8s connect` | ⏳ Pending |

> **Run once to provision Azure resources:**
> ```bash
> cd infrastructure/terraform
> terraform init
> terraform apply
> ```

---

## What Gets Deployed to MedionK3s

| Component | Kind | How it lands |
|---|---|---|
| **Azure Arc Agent** | Pods in `azure-arc` ns | `az connectedk8s connect` (one-time) |
| **`acr-secret`** | Kubernetes Secret | `kubectl create secret docker-registry` (one-time) |
| **`fastapi-app`** | Deployment (2 pods) | GitHub Actions on every push to `main` |
| **`fastapi-service`** | Service (LoadBalancer) | `kubectl apply -f` on first deploy / `scripts/deploy.sh` |

> **One-time setup commands on MedionK3s:**
>
> **1. Register cluster with Azure Arc:**
> ```bash
> az connectedk8s connect --name MedionK3s --resource-group fastapi-resource-group
> ```
>
> **2. Add GitHub Secret `KUBE_CONFIG`** (run on the machine with kubeconfig access):
> ```bash
> cat ~/.kube/config | base64 -w 0 | gh secret set KUBE_CONFIG --repo idsme/fastapi-aks-gh-actions
> ```
>
> **3. Create ACR pull secret on the cluster:**
> ```bash
> ACR_PASSWORD=$(az acr credential show --name fastapiacr12345 --query passwords[0].value -o tsv)
> kubectl create secret docker-registry acr-secret \
>   --docker-server=fastapiacr12345.azurecr.io \
>   --docker-username=fastapiacr12345 \
>   --docker-password=$ACR_PASSWORD
> ```
>
> **4. Apply Kubernetes manifests (first time only):**
> ```bash
> kubectl apply -f infrastructure/kubernetes/deployment.yaml
> kubectl apply -f infrastructure/kubernetes/service.yaml
> ```

---

## CI/CD Flow (every push to `main`)

```
Developer → git push main
    → GitHub Actions triggers
        → az login (AZURE_CREDENTIALS)
        → docker build
        → docker push → ACR
        → kubectl (KUBE_CONFIG)
            → kubectl set image deployment/fastapi-app
            → kubectl rollout restart
            → kubectl rollout status  ← pipeline blocks here until healthy
```
