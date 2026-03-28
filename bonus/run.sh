#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR"

# ── Enregistrer le repo GitLab dans Argo CD ──────────────────────────
echo "[+] Enregistrement du repo GitLab dans Argo CD..."
kubectl apply -f argocd/repo-secret.yaml

# ── Deployer l'application via Argo CD ───────────────────────────────
echo "[+] Deploiement de l'application Argo CD..."
kubectl apply -f argocd/application.yaml

# ── Attendre le pod my-app ───────────────────────────────────────────
echo "[~] Attente du pod my-app dans le namespace dev..."
kubectl wait --for=condition=Ready pod -l app=my-app -n dev --timeout=180s

# ── Port-forwards ────────────────────────────────────────────────────
echo "[+] Ouverture des port-forwards..."

kubectl port-forward svc/argocd-server -n argocd 8080:443 &
echo "  Argo CD UI  -> http://localhost:8080"

kubectl port-forward svc/gitlab -n gitlab 8181:80 &
echo "  GitLab      -> http://localhost:8181"

kubectl port-forward svc/my-app -n dev 8888:80 &
echo "  my-app      -> http://localhost:8888"

echo ""
echo "============================================"
echo "  Tous les services sont accessibles :"
echo "    Argo CD  : http://localhost:8080  (admin / voir init.sh)"
echo "    GitLab   : http://localhost:8181  (root / password42)"
echo "    my-app   : http://localhost:8888"
echo ""
echo "  Ctrl+C pour stopper les port-forwards."
echo "============================================"
wait
