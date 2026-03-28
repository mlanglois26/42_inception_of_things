#!/bin/bash
set -e

CLUSTER_NAME="IOT-cluster"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR"

# ── k3d ──────────────────────────────────────────────────────────────
if ! command -v k3d &> /dev/null; then
    echo "[+] Installation de k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "[ok] k3d deja installe."
fi

# ── Cluster ──────────────────────────────────────────────────────────
if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    echo "[~] Suppression du cluster existant..."
    k3d cluster delete "$CLUSTER_NAME"
fi

echo "[+] Creation du cluster $CLUSTER_NAME..."
k3d cluster create "$CLUSTER_NAME" --servers 1 --agents 1 --wait

# ── Namespaces ───────────────────────────────────────────────────────
echo "[+] Creation des namespaces (dev, argocd, gitlab)..."
kubectl apply -f ../p3/dev/namespace.yaml
kubectl apply -f ../p3/argocd/namespace.yaml
kubectl apply -f gitlab/namespace.yaml

# ── Argo CD ──────────────────────────────────────────────────────────
echo "[+] Installation d'Argo CD..."
kubectl apply -n argocd --server-side=true \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "[~] Attente qu'Argo CD soit pret..."
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-server -n argocd --timeout=180s

echo ""
echo "[ok] Mot de passe Argo CD (admin) :"
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
echo ""

# ── GitLab CE ────────────────────────────────────────────────────────
echo "[+] Deploiement de GitLab CE..."
kubectl apply -f gitlab/deployment.yaml
kubectl apply -f gitlab/service.yaml

echo "[~] Attente que GitLab demarre (cela peut prendre 3-5 min)..."
kubectl wait --for=condition=Available deployment/gitlab -n gitlab --timeout=600s

echo ""
echo "============================================"
echo "  init.sh termine avec succes"
echo "  Prochaine etape : ./setup-repo.sh"
echo "============================================"
