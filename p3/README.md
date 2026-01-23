# KD3 et ArgoCD

---

Le but de l'exo

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

Creation du Cluster
faire l'init sh cluster
faire l'init sh des les cli k3s

</details>

<details>
  <summary>Les Namespaces</summary>
  <br>
C'est une isolation logique pour organiser les ressources
Un namespace peut avoir ses pods sur plusieurs nodes, et plusieurs namespaces peuvent partager les mêmes nodes

💡 Exemple :

Namespace dev → 3 pods
Namespace prod → 5 pods
Cluster avec 2 nodes → les 8 pods peuvent être répartis sur ces 2 nodes selon l’ordonnancement de Kubernetes

Bonnes pratiques :

Namespaces → utiliser pour organiser, isoler, gérer les droits d’accès et quotas
Nodes → dimensionner selon le nombre de pods, la charge, la résilience
Ne pas créer un node pour chaque namespace → ça devient inutile et compliqué à gérer

Donc pour ton setup :

2 namespaces → isolation logique (argocd vs dev)

2 nodes workers → capacité et répartition des pods

Les pods de argocd et dev peuvent cohabiter sur les mêmes nodes.
 
</details>

<details>
  <summary>ArgoCD</summary>
  <br>

 - C'est quoi ?

Argo CD est un outil GitOps pour Kubernetes.

GitOps : méthode pour gérer ton cluster Kubernetes à partir de Git

Ton dépôt Git devient la “source de vérité” pour l’état désiré de tes applications

Kubernetes n’a qu’à appliquer ce qui est défini dans Git

Argo CD observe ton Git et fait en sorte que ton cluster corresponde toujours à ce que tu as défini dans Git.

Si un pod est supprimé manuellement → Argo CD peut le recréer automatiquement

Si tu modifies un manifeste dans Git → Argo CD met à jour ton cluster

- C'est quoi la diff avec une Github Action ?

- Accéder à l'UI
</details>


---

### Application.yaml

C'est un objet ArgoCD
Contrairement au deployment, service et à l'ingress qui sont des objets Kubernetes.
Donc le application.yaml ne créer pas de pods

Son rôle, c'est de dire à ArgoCD, observe ce repo git et applique tout ce qui est là dans le cluster

