#!/bin/bash
set -e

# Installer K3s
curl -sfL https://get.k3s.io | sh -

# Exporter kubeconfig pour kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Attendre que le server K3s soit prêt
until kubectl get nodes &>/dev/null; do
  echo "Waiting for kube-apiserver..."
  sleep 2
done

# Déployer les applications

kubectl create configmap app1-index --from-file app1/index.html # revoir tout ça

kubectl apply -f /apps/app1/deploy.yaml
kubectl apply -f /apps/app1/service.yaml

kubectl apply -f /apps/app2/deploy.yaml
kubectl apply -f /apps/app2/service.yaml

kubectl apply -f /apps/app3/deploy.yaml
kubectl apply -f /apps/app3/service.yaml