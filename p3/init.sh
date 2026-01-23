#!/bin/bash
set -e

CLUSTER_NAME="mycluster"

# 1️⃣ Installer k3d si pas présent
if ! command -v k3d &> /dev/null; then
    echo "Installation de k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d déjà installé."
fi

# 2️⃣ Supprimer le cluster existant si présent
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "Suppression du cluster existant..."
    k3d cluster delete $CLUSTER_NAME
fi

# 3️⃣ Créer le cluster
echo "Création du cluster $CLUSTER_NAME..."
k3d cluster create $CLUSTER_NAME --servers 1 --agents 1 --wait

# 4️⃣ Créer namespace Argo CD depuis fichier
echo "Création du namespace argocd..."
kubectl apply -f argocd/namespace.yaml

# 5️⃣ Installer Argo CD officiel
echo "Installation d'Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 6️⃣ Créer namespace dev depuis fichier
echo "Création du namespace dev..."
kubectl apply -f dev/namespace.yaml

echo "Cluster et Argo CD prêts ✅"
echo "Pour accéder à l'UI Argo CD :"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Login: admin"
echo "Password:"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
echo ""

# ajouter les apply d'ingresses, deploy et service