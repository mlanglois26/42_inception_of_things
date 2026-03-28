# Bonus - GitLab local avec Argo CD

## Pourquoi ce bonus ?

Dans la Part 3, Argo CD pull les manifests depuis **GitHub** -- un service
externe, heberge sur internet, sur lequel on n'a aucun controle.

Le bonus remplace GitHub par une instance **GitLab auto-hebergee** qui tourne
directement dans le cluster. Le resultat fonctionnel est le meme (GitOps avec
Argo CD), mais l'interet est ailleurs :

- **Autonomie complete (air-gapped)** : tout fonctionne sans connexion
  internet une fois deploye. En entreprise (banques, defense, sante), les
  environnements sont souvent isoles du net ; impossible d'utiliser GitHub.
- **Maitrise de l'infra Git** : savoir deployer, configurer et maintenir un
  serveur Git en interne est une competence DevOps cle.
- **Networking interne Kubernetes** : Argo CD communique avec GitLab via le
  DNS interne du cluster (`gitlab.gitlab.svc.cluster.local`), ce qui montre
  la comprehension des services, du DNS et de la communication inter-namespaces.
- **Pipeline GitOps maitrise de bout en bout** : on controle toute la chaine,
  du depot Git au deploiement, sans dependre d'un service cloud externe.

```
Avec GitHub (p3) :
  push sur GitHub (externe) --> ArgoCD pull --> deploy

Avec GitLab local (bonus) :
  push sur GitLab (dans le cluster) --> ArgoCD pull --> deploy
  tout est local, on controle tout
```

En resume, la plupart des entreprises utilisent GitLab self-hosted (ou Gitea,
Bitbucket Server...) plutot que GitHub.com. Ce bonus simule un environnement
de production realiste.

## Architecture

```
+------------------------------------------------------------------+
|                   k3d cluster  IOT-cluster                       |
|                                                                  |
|  +-- namespace: gitlab ----------------------------------------+ |
|  |                                                             | |
|  |   [Pod gitlab]              [Service gitlab]                | |
|  |    gitlab/gitlab-ce:latest   ClusterIP :80 / :22            | |
|  |    ports: 80 (http), 22      gitlab.gitlab.svc.cluster.local| |
|  |                                                             | |
|  +-------------------------------------------------------------+ |
|         |                                                        |
|         | http://gitlab.gitlab.svc.cluster.local/root/iot-bonus   |
|         |   (DNS interne K8s)                                    |
|         v                                                        |
|  +-- namespace: argocd ----------------------------------------+ |
|  |                                                             | |
|  |   [Pod argocd-server]       [Service argocd-server]         | |
|  |    argocd-server             ClusterIP :443                 | |
|  |                                                             | |
|  |   [Pod argocd-repo-server]  [Pod argocd-app-controller]     | |
|  |                                                             | |
|  +-------------------------------------------------------------+ |
|         |                                                        |
|         | kubectl apply (deploiement automatique)                 |
|         v                                                        |
|  +-- namespace: dev -------------------------------------------+ |
|  |                                                             | |
|  |   [Pod my-app]              [Service my-app]                | |
|  |    wil42/playground:v1       ClusterIP :80 -> :8888         | |
|  |    port: 8888                                               | |
|  |                                                             | |
|  +-------------------------------------------------------------+ |
|                                                                  |
+------------------------------------------------------------------+
         |               |               |
    port-forward    port-forward    port-forward
         |               |               |
         v               v               v
   localhost:8181   localhost:8080   localhost:8888
     (GitLab)        (Argo CD)       (my-app)
```

Argo CD surveille le repo GitLab local et deploie automatiquement
l'application `my-app` dans le namespace `dev`.

**Flux GitOps :**
1. L'utilisateur pousse des manifests dans le repo `iot-bonus` sur GitLab
2. Argo CD detecte le changement (poll periodique via DNS interne)
3. Argo CD applique les manifests dans le namespace `dev`
4. Le pod `my-app` est cree/mis a jour automatiquement

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
