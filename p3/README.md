# KD3 et ArgoCD

---

Le but de l'exo est d'utiliser :

- k3d, c'est à dire Kubernetes dans Docker
- ArgoCD, c'est à dire un GitOps controller

k3d qui est un moyen de lancer un cluster kubernetes local dans des containeurs Docker. Le kube-apiserver et les nodes tournent dans des containers Docker. 

L'installation d'ArgoCD déploie plusieurs pods dans le cluster k3d dont :
 - argocd-server (UI/API)
 - argocd-repo-server
 argocd-application-controller

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
  Si le cluster existe déjà, on le supprime. Sinon on le créer avec un node server et un node agent
  -- wait pour bloquer la commande et attendre que le cluster soit prêt avant le lancer les objets Kubernetes
  ```bash
  k3d cluster create $CLUSTER_NAME --servers 1 --agents 1 --wait
  ```
</details>

<details>
  <summary>Les Namespaces</summary>
  <br>

  - Un namespace, c'est une isolation logique pour organiser les ressources
  - Un namespace peut avoir ses pods sur plusieurs nodes, et plusieurs namespaces peuvent partager les mêmes nodes (c'est Kubernetes qui gère l'ordonnance)

  💡 Bonnes pratiques :

  - Namespaces → utiliser pour organiser, isoler, gérer les droits d’accès et quotas
  - Nodes → dimensionner selon le nombre de pods, la charge, la résilience
  - Ne pas créer un node pour chaque namespace → ça devient inutile et compliqué à gérer

  <table>
    <tr>
      <td><img src="../images/namespace.png" alt="namespace"/></td>
    </tr>
  </table>
 
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
    💡 Donc en gros, Kubernetes obéit à Git. Plus besoin de `kubectl apply` les `deployements`, les `services` et les `ingress` à la main

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

- <u>Accéder à l'UI ArgoCD</u>

  Attends que le pod UI (argocd-server) soit prêt avec :
  ```ruby
  kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s
  ```
  
  Ouvre un tunnel depuis la vm vers ArgoCD
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  ```
  L'UI sera sur ***http://localhost:8080***


  Pour s'y connecter, ArgoCD créer automatiquement un mot de passe admin initial
  Il le stock dans un secret Kubernetes intitulé ***argocd-initial-admin-secret***, il faut donc le récupérer avec :
  ```bash
  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
  ```
  - extrait la valeur du password avec jsonpath
  - décode avec base64 -d
</details>

---

### Application.yaml

C'est un objet ArgoCD
Contrairement au deployment, service et à l'ingress qui sont des objets Kubernetes.
Donc le application.yaml ne créer pas de pods
a verifier ça 

Son rôle, c'est de dire à ArgoCD, observe ce repo git et applique tout ce qui est là dans le cluster

Un manifest = un objet au sens kubernetes