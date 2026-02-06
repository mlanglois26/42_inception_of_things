#!/bin/bash
set -e

# 1️⃣ Déployer l'application via Argo CD
echo "Déploiement de l'application Argo CD..."
kubectl apply -f argocd/application.yaml

# 2️⃣ Attendre que le pod my-app soit prêt dans le namespace dev
echo "Attente du pod my-app..."
kubectl wait --for=condition=Ready pod -l app=my-app -n dev --timeout=120s

# 3️⃣ Ouvrir les tunnels port-forward
echo "Port-forward Argo CD UI   → http://localhost:8080"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

echo "Port-forward my-app       → http://localhost:8888"
kubectl port-forward svc/my-app -n dev 8888:80 &

echo ""
echo "Accès :"
echo "  Argo CD UI → http://localhost:8080"
echo "  App        → http://localhost:8888"
echo ""
echo "Ctrl+C pour stopper les port-forwards."
wait
