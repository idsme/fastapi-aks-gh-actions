docker build -t acrakstraineeidsme.azurecr.io/fastapi-app:latest .  # Build the Docker image from the current directory and tag it with the full ACR registry path
docker push acrakstraineeidsme.azurecr.io/fastapi-app:latest  # Push the tagged image up to Azure Container Registry for storage
kubectl config use-context MedionK3s  # Switch kubectl to the MedionK3s context (ensure kubeconfig is set up locally before running this script)
kubectl get nodes  # List all cluster nodes to verify MedionK3s is reachable and all nodes are in Ready state
cd infrastructure/kubernetes/  # Change into the directory that contains the Kubernetes manifest files
kubectl apply -f deployment.yaml  # Apply the Kubernetes Deployment manifest to create or update the application pods
kubectl apply -f service.yaml  # Apply the Kubernetes Service manifest to create or update the LoadBalancer Service
