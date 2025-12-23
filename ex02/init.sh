#!/bin/bash
set -e

# 1️⃣ Installer k3d si ce n'est pas déjà fait
if ! command -v k3d &> /dev/null
then
    echo "Installation de k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d déjà installé."
fi

# 2️⃣ Créer un cluster K3d
CLUSTER_NAME="mycluster"
echo "Création du cluster K3d : $CLUSTER_NAME..."
k3d cluster create $CLUSTER_NAME --servers 1 --agents 2 --wait

# 3️⃣ Vérifier les nodes
echo "Vérification des nodes..."
kubectl get nodes

# 4️⃣ Créer les namespaces
echo "Création des namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "Cluster et namespaces prêts ✅"

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
