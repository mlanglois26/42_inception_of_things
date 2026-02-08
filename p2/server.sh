#!/bin/bash
set -e

SERVER_IP="192.168.56.110"

# Installer K3s
curl -sfL https://get.k3s.io | sh -s -- \
  --node-ip "${SERVER_IP}" \
  --advertise-address "${SERVER_IP}" \
  --tls-san "${SERVER_IP}"

# Attendre que le server K3s soit prêt
until kubectl get nodes &>/dev/null; do
  echo "Waiting for kube-apiserver..."
  sleep 2
done

# Créer les ConfigMaps avant les déploiements
kubectl create configmap app1-index --from-file=/apps/app1/index.html --save-config -o yaml --dry-run=client | kubectl apply -f -
kubectl create configmap app3-index --from-file=/apps/app3/index.html --save-config -o yaml --dry-run=client | kubectl apply -f -


# Déployer les pods et les services
kubectl apply -f /apps/app1/deploy.yaml
kubectl apply -f /apps/app1/service.yaml

kubectl apply -f /apps/app2/deploy.yaml
kubectl apply -f /apps/app2/service.yaml

kubectl apply -f /apps/app3/deploy.yaml
kubectl apply -f /apps/app3/service.yaml

# Déployer l'ingress
kubectl apply -f /ingress/ingress.yaml