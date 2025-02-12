docker build -t fastapiacr12345.azurecr.io/fastapi-app:latest .
docker push fastapiacr12345.azurecr.io/fastapi-app:latest
az aks get-credentials --admin --name fastapi-aks-cluster --resource-group fastapi-resource-group
kubectl get nodes
cd infrastructure/kubernetes/
kubectl apply -f service.yaml 
kubectl apply -f service.yaml 