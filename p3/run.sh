#!/bin/bash
set -e

echo "Déploiement de l'application Argo CD..."
kubectl apply -f argocd/application.yaml

# Attendre qu'Argo CD synchronise et crée le pod
echo "Attente de la synchronisation Argo CD..."
until kubectl get pod -l app=playground -n dev 2>/dev/null | grep -q playground; do
  sleep 3
done

# Attendre que le pod soit Ready
echo "Attente que le pod playground soit prêt..."
kubectl wait --for=condition=Ready pod -l app=playground -n dev --timeout=120s

# echo "Port-forward Argo CD UI   → http://localhost:8080"
# kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# echo "Port-forward playground   → http://localhost:8888"
# kubectl port-forward svc/playground-svc -n dev 8888:80 &

# echo ""
# echo "Accès :"
# echo "  Argo CD UI → http://localhost:8080"
# echo "  App        → http://localhost:8888"
# echo ""
# echo "Ctrl+C pour stopper les port-forwards."
# wait

echo "Done"
