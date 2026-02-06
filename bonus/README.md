# Bonus - GitLab local avec Argo CD

## Architecture

```
k3d cluster IOT-cluster
 ├── namespace: gitlab    -> GitLab CE (instance locale)
 ├── namespace: argocd    -> Argo CD (GitOps)
 └── namespace: dev       -> my-app (wil42/playground:v1)

Flux :
  GitLab (repo iot-bonus) ──git pull──> Argo CD ──deploy──> my-app (dev)
```

Argo CD surveille le repo GitLab local et deploie automatiquement
l'application `my-app` dans le namespace `dev`.

## Pre-requis

- **k3d** (installe automatiquement par init.sh si absent)
- **kubectl**
- **git**
- **curl**
- **~8 Go de RAM libre** (GitLab CE est gourmand)

## Utilisation

Les scripts doivent etre executes depuis le dossier `bonus/`.

```bash
cd bonus
```

### Etape 1 : Initialisation du cluster

Cree le cluster k3d, installe Argo CD et deploie GitLab CE.

```bash
chmod +x init.sh setup-repo.sh run.sh
./init.sh
```

> GitLab met environ 3-5 minutes a demarrer completement.

### Etape 2 : Configuration du repo GitLab

Cree un projet dans GitLab et y pousse les manifests de p3/dev.

```bash
./setup-repo.sh
```

Ce script :
- Ouvre un port-forward temporaire vers GitLab
- Cree un token d'acces (via gitlab-rails)
- Cree le projet `iot-bonus` (public)
- Pousse deployment.yaml, service.yaml, namespace.yaml, ingress.yaml

### Etape 3 : Lancement

Configure Argo CD pour utiliser le repo GitLab et demarre les port-forwards.

```bash
./run.sh
```

## Acces aux services

| Service   | URL                     | Identifiants               |
|-----------|-------------------------|-----------------------------|
| Argo CD   | http://localhost:8080   | admin / (affiche par init.sh) |
| GitLab    | http://localhost:8181   | root / password42           |
| my-app    | http://localhost:8888   | -                           |

## Structure des fichiers

```
bonus/
  init.sh              # Cree cluster + installe ArgoCD + GitLab
  setup-repo.sh        # Configure le repo GitLab
  run.sh               # Lance ArgoCD app + port-forwards
  README.md
  gitlab/
    namespace.yaml     # Namespace gitlab
    deployment.yaml    # GitLab CE (image gitlab/gitlab-ce:latest)
    service.yaml       # Service ClusterIP pour GitLab
  argocd/
    application.yaml   # Application ArgoCD -> repo GitLab local
    repo-secret.yaml   # Credentials du repo GitLab pour ArgoCD
```

## Communication interne

Argo CD communique avec GitLab via le DNS interne Kubernetes :
```
http://gitlab.gitlab.svc.cluster.local/root/iot-bonus.git
```

Aucune configuration reseau externe n'est necessaire.
Les port-forwards servent uniquement a l'acces depuis la machine hote.

## Nettoyage

```bash
k3d cluster delete IOT-cluster
```
