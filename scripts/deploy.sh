docker build -t fastapiacr12345.azurecr.io/fastapi-app:latest .  # Build the Docker image from the current directory and tag it with the full ACR registry path
docker push fastapiacr12345.azurecr.io/fastapi-app:latest  # Push the tagged image up to Azure Container Registry for storage
az aks get-credentials --admin --name fastapi-aks-cluster --resource-group fastapi-resource-group  # Download admin kubeconfig for the AKS cluster so kubectl commands can authenticate and connect
kubectl get nodes  # List all cluster nodes to verify the cluster is reachable and all nodes are in Ready state
cd infrastructure/kubernetes/  # Change into the directory that contains the Kubernetes manifest files
kubectl apply -f deployment.yaml  # Apply the Kubernetes Deployment manifest to create or update the application pods
kubectl apply -f service.yaml  # Apply the Kubernetes Service manifest to create or update the LoadBalancer Service
