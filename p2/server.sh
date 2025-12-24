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

#
kubectl create configmap app1-index --from-file /apps/app1/index.html
kubectl create configmap app2-index --from-file /apps/app2/index.html
kubectl create configmap app3-index --from-file /apps/app3/index.html

# Déployer les applications
kubectl apply -f /apps/app1/deploy.yaml
kubectl apply -f /apps/app1/service.yaml

kubectl apply -f /apps/app2/deploy.yaml
kubectl apply -f /apps/app2/service.yaml

kubectl apply -f /apps/app3/deploy.yaml
kubectl apply -f /apps/app3/service.yaml