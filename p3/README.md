# KD3 et ArgoCD

---

Le but de l'exo est d'utiliser :

- **k3d** : un moyen de lancer un cluster Kubernetes local dans des conteneurs Docker. Le kube-apiserver et les nodes tournent dans des containers Docker.
- **ArgoCD** : un GitOps controller pour Kubernetes.

L'installation d'ArgoCD déploie plusieurs pods dans le cluster k3d dont :
 - argocd-server (UI/API)
 - argocd-repo-server
 - argocd-application-controller

### Architecture

```mermaid
graph TB
    subgraph Host["Machine hote"]
        direction TB
        Docker["Docker Engine"]
        kubectl["kubectl"]

        subgraph K3D["Cluster k3d IOT-cluster"]
            direction TB

            subgraph ServerNode["Server Node - container Docker"]
                KubeAPI["kube-apiserver"]
            end

            subgraph AgentNode["Agent Node - container Docker"]
                direction TB

                subgraph NSargocd["Namespace argocd"]
                    argoServer["argocd-server :443"]
                    argoRepo["argocd-repo-server"]
                    argoController["argocd-application-controller"]
                end

                subgraph NSdev["Namespace dev"]
                    DeployMyApp["Deployment my-app"]
                    PodMyApp["Pod my-app :8888"]
                    SvcMyApp["Service my-app :80"]
                end
            end
        end
    end

    GitHub["GitHub Repo - mlanglois26/42_inception_of_things - branch main, path p3/dev"]
    Browser["Navigateur"]

    argoController -->|"watch + sync"| GitHub
    GitHub -.->|"deployment.yaml, service.yaml, ingress.yaml"| argoController
    argoController -->|"apply manifests"| NSdev

    DeployMyApp --> PodMyApp
    SvcMyApp -->|"targetPort 8888"| PodMyApp

    Browser -->|"localhost:8080"| argoServer
    Browser -->|"localhost:8888"| SvcMyApp

    kubectl -->|"port-forward 8080:443"| argoServer
    kubectl -->|"port-forward 8888:80"| SvcMyApp
```

---

### Prérequis : Docker & kubectl

k3d fait tourner les nœuds Kubernetes dans des conteneurs Docker, et `kubectl` est nécessaire pour interagir avec le cluster. Il faut donc les installer sur la machine hôte avant de lancer `init.sh`.

<details>
  <summary>Installer Docker</summary>
  <br>

  ```bash
  sudo apt-get update
  sudo apt-get install -y docker.io
  ```

  Démarrer le daemon et l'activer au boot :
  ```bash
  sudo systemctl start docker
  sudo systemctl enable docker
  ```

  Ajouter ton utilisateur au groupe `docker` (pour ne pas avoir besoin de `sudo` à chaque commande) :
  ```bash
  sudo usermod -aG docker $USER
  ```
  Puis **se déconnecter / reconnecter** (ou `newgrp docker`) pour que le changement prenne effet.

  Vérifier que Docker tourne :
  ```bash
  docker ps
  ```
</details>

<details>
  <summary>Installer kubectl</summary>
  <br>

  `kubectl` est le CLI pour piloter un cluster Kubernetes. k3d crée le cluster et configure le kubeconfig, mais il ne fournit pas `kubectl`.

  ```bash
  sudo snap install kubectl --classic
  ```

  Vérifier l'installation :
  ```bash
  kubectl version --client
  ```
</details>

---

### Init.sh

<details>
  <summary>Installation de K3d</summary>
  <br>

  Vérifier si l'exécutable k3d est présent avec 
  ```bash
  command -v k3d
  ```
  Rediriger stdout et stderr /dev/null pour ne rien afficher
  ```bash
  &> /dev/null
  ```
  Télécharger et installer k3d via le script officiel (-s pour silent mode pour moins de message)
  ```bash
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  ```
  Si le cluster existe déjà, on le supprime :
  ```bash
  k3d cluster list | grep -q "$CLUSTER_NAME" && k3d cluster delete $CLUSTER_NAME
  ```
  Puis on le crée avec un node server et un node agent.
  `--wait` bloque la commande et attend que le cluster soit prêt avant de lancer les objets Kubernetes :
  ```bash
  k3d cluster create $CLUSTER_NAME --servers 1 --agents 1 --wait
  ```
</details>

<details>
  <summary>Les Namespaces</summary>
  <br>

  - Un namespace, c'est une isolation logique pour organiser les ressources
  - Un namespace peut avoir ses pods sur plusieurs nodes, et plusieurs namespaces peuvent partager les mêmes nodes (c'est Kubernetes qui gère l'ordonnancement)

  💡 Bonnes pratiques :

  - Namespaces → utiliser pour organiser, isoler, gérer les droits d’accès et quotas
  - Nodes → dimensionner selon le nombre de pods, la charge, la résilience
  - Ne pas créer un node pour chaque namespace → ça devient inutile et compliqué à gérer

  <table>
    <tr>
      <td><img src="../images/namespace.png" alt="namespace"/></td>
    </tr>
  </table>

  Dans `init.sh`, on crée deux namespaces via leurs fichiers YAML :
  ```bash
  kubectl apply -f dev/namespace.yaml      # namespace "dev" pour l'application
  kubectl apply -f argocd/namespace.yaml   # namespace "argocd" pour Argo CD
  ```

</details>

<details>
  <summary>ArgoCD</summary>
  <br>

 - <u>C'est quoi ?</u>

    - Argo CD est un outil GitOps pour Kubernetes.
    - GitOps : méthode pour gérer ton cluster Kubernetes à partir de Git
    - Ton dépôt Git devient la “source de vérité” pour l’état désiré de tes applications
    - Kubernetes n’a qu’à appliquer ce qui est défini dans Git
    - Argo CD observe ton Git et fait en sorte que ton cluster corresponde toujours à ce que tu as défini dans Git.
    - Si un pod est supprimé manuellement → Argo CD peut le recréer automatiquement
    - Si tu modifies un manifeste dans Git → Argo CD met à jour ton cluster
    <br>
    💡 Donc en gros, Kubernetes obéit à Git. Plus besoin de `kubectl apply` les `deployments`, les `services` et les `ingress` à la main

<br>

- <u>C'est quoi la diff avec une Github Action ?</u>

    - Avec la GitHubAction, il faudrait décrire la step. On aurait toujours le .yaml avec notre `kubectl apply`

| Aspect              | CI/CD classique                  | GitOps / Argo CD                                 |
| ------------------- | -------------------------------- | ------------------------------------------------ |
| Déploiement         | `kubectl apply` dans un workflow | Argo CD lit Git et applique tout automatiquement |
| Surveillance        | Aucune                           | Argo CD monitor le cluster et Git                |
| Gestion des dérives | Manuelle                         | Auto-heal / reconcile                            |
| Workflow Git        | “push → CI → apply → cluster”    | “push → Argo CD synchronise → cluster”           |
| Qui applique        | Runner GitHub Actions            | Argo CD (controller dans le cluster)             |


<br>

- <u>Installation dans init.sh</u>

  On installe ArgoCD via le manifest officiel avec `--server-side=true` (nécessaire car certaines CRDs dépassent la taille max d'annotation côté client) :
  ```bash
  kubectl apply -n argocd --server-side=true -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  ```

  > 💡 Le comportement "auto-heal" (recréer un pod supprimé manuellement, corriger une dérive) n'est pas activé par défaut dans ArgoCD.
  > C'est le `syncPolicy.automated` avec `selfHeal: true` et `prune: true` dans l'`Application.yaml` qui l'active.

<br>

- <u>Accéder à l'UI ArgoCD</u>

  Attends que le pod UI (argocd-server) soit prêt avec :
  ```bash
  kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s
  ```
  
  Ouvre un tunnel depuis la vm vers ArgoCD
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  ```
  L'UI sera sur ***http://localhost:8080***


  Pour s'y connecter, ArgoCD crée automatiquement un mot de passe admin initial.
  Il le stocke dans un secret Kubernetes intitulé ***argocd-initial-admin-secret***, il faut donc le récupérer avec :
  ```bash
  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
  ```
  - extrait la valeur du password avec jsonpath
  - décode avec base64 -d
</details>

---

### Run.sh et connexion des ports

<details>
  <summary>Comment les ports sont connectés</summary>
  <br>

  Le cluster k3d tourne dans Docker. Les services Kubernetes ne sont pas directement accessibles depuis la machine hôte. On utilise `kubectl port-forward` pour créer un tunnel entre un port local et un service du cluster.

  ```
  Machine hôte                Cluster k3d (Docker)
  ─────────────               ────────────────────────────────

  localhost:8080  ──tunnel──▶  svc/argocd-server:443  ──▶  pod argocd-server
  localhost:8888  ──tunnel──▶  svc/my-app:80          ──▶  pod my-app:8888
  ```

  | Port local | Service Kubernetes | Port du service | Port du conteneur | Accès |
  |---|---|---|---|---|
  | 8080 | `svc/argocd-server` (namespace argocd) | 443 | 8080 | http://localhost:8080 |
  | 8888 | `svc/my-app` (namespace dev) | 80 | 8888 | http://localhost:8888 |

  - **`svc/my-app` port 80 → targetPort 8888** : le Service écoute sur le port 80 et redirige vers le port 8888 du conteneur (celui sur lequel l'image `wil42/playground` écoute)
  - **`port-forward 8888:80`** : mappe le port 8888 de la machine hôte vers le port 80 du Service

  `run.sh` lance les deux port-forwards en arrière-plan. `Ctrl+C` les stoppe.
</details>

---

### Application.yaml

C'est un objet ArgoCD
Contrairement au deployment, service et à l'ingress qui sont des objets Kubernetes.
Donc le application.yaml ne créer pas de pods
a verifier ça 

Son rôle, c'est de dire à ArgoCD, observe ce repo git et applique tout ce qui est là dans le cluster

Un manifest = un objet au sens kubernetes