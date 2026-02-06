#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITLAB_PORT=8181
GITLAB_URL="http://localhost:${GITLAB_PORT}"
GITLAB_PASSWORD="password42"
TOKEN="glpat-setup-token-42"
PROJECT_NAME="iot-bonus"
TEMP_DIR=$(mktemp -d)

cd "$SCRIPT_DIR"

# ── Port-forward GitLab ──────────────────────────────────────────────
echo "[+] Ouverture du port-forward vers GitLab (localhost:${GITLAB_PORT})..."
kubectl port-forward svc/gitlab -n gitlab ${GITLAB_PORT}:80 &
PF_PID=$!
sleep 3

cleanup() {
    echo "[~] Fermeture du port-forward..."
    kill $PF_PID 2>/dev/null || true
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ── Attendre que GitLab soit pret via l'API ──────────────────────────
echo "[~] Attente que l'API GitLab reponde..."
MAX_RETRIES=60
for i in $(seq 1 $MAX_RETRIES); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${GITLAB_URL}/-/readiness" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo "[ok] GitLab API prete."
        break
    fi
    if [ "$i" = "$MAX_RETRIES" ]; then
        echo "[ERREUR] GitLab n'a pas repondu apres ${MAX_RETRIES} tentatives."
        exit 1
    fi
    echo "  tentative $i/$MAX_RETRIES (status: $STATUS)..."
    sleep 10
done

# ── Creer un Personal Access Token via rails ─────────────────────────
echo "[+] Creation du token d'acces dans GitLab..."
kubectl exec deploy/gitlab -n gitlab -- gitlab-rails runner "
  user = User.find_by_username('root')
  token = user.personal_access_tokens.create(
    name: 'setup',
    scopes: ['api', 'write_repository', 'read_repository'],
    expires_at: 365.days.from_now
  )
  token.set_token('${TOKEN}')
  token.save!
  puts 'Token cree avec succes'
"

# ── Creer le projet dans GitLab ──────────────────────────────────────
echo "[+] Creation du projet ${PROJECT_NAME}..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "PRIVATE-TOKEN: ${TOKEN}" \
  -X POST "${GITLAB_URL}/api/v4/projects" \
  -d "name=${PROJECT_NAME}&visibility=public&initialize_with_readme=false")

if [ "$HTTP_CODE" = "201" ]; then
    echo "[ok] Projet cree."
elif [ "$HTTP_CODE" = "400" ]; then
    echo "[ok] Projet existe deja."
else
    echo "[ERREUR] Creation du projet echouee (HTTP $HTTP_CODE)."
    exit 1
fi

# ── Pousser les manifests p3/dev dans le repo GitLab ─────────────────
echo "[+] Push des manifests dans GitLab..."
cd "$TEMP_DIR"
git init -b main
git remote add origin "http://oauth2:${TOKEN}@localhost:${GITLAB_PORT}/root/${PROJECT_NAME}.git"

# Copier les manifests de p3/dev
cp "$SCRIPT_DIR"/../p3/dev/deployment.yaml .
cp "$SCRIPT_DIR"/../p3/dev/service.yaml .
cp "$SCRIPT_DIR"/../p3/dev/namespace.yaml .
cp "$SCRIPT_DIR"/../p3/dev/ingress.yaml .

git add -A
git -c user.name="root" -c user.email="root@gitlab.local" commit -m "Initial commit - app manifests"
git push -u origin main

echo ""
echo "============================================"
echo "  setup-repo.sh termine avec succes"
echo "  Repo : ${GITLAB_URL}/root/${PROJECT_NAME}"
echo "  Prochaine etape : ./run.sh"
echo "============================================"
