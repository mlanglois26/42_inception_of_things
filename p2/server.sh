#!/bin/bash
set -e

# Installer K3s
curl -sfL https://get.k3s.io | sh -

mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config

# Exporter kubeconfig pour kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Attendre que le server K3s soit prêt
until kubectl get nodes &>/dev/null; do
  echo "Waiting for kube-apiserver..."
  sleep 2
done

# Créer les ConfigMaps avant les déploiements
kubectl create configmap app1-index --from-file=/apps/app1/index.html --save-config -o yaml --dry-run=client | kubectl apply -f -
kubectl create configmap app3-index --from-file=/apps/app3/index.html --save-config -o yaml --dry-run=client | kubectl apply -f -
# enlver le create
# faire kubectl rollout restart le deploy si on touche au fichier 

# -f pour file
# Déployer les pods et les services
kubectl apply -f /apps/app1/deploy.yaml
kubectl apply -f /apps/app1/service.yaml

kubectl apply -f /apps/app2/deploy.yaml
kubectl apply -f /apps/app2/service.yaml

kubectl apply -f /apps/app3/deploy.yaml
kubectl apply -f /apps/app3/service.yaml

# Déployer l'ingress
kubectl apply -f /ingress/ingress.yaml