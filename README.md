# 42_inception_of_things

Le projet doit être réalisé dans une **VM**.
On va créer des VM dans une VM. On va donc faire de la nested virtualization. (Donc on va avoir beson de pas mal de RAM et plusieurs processeurs).

## Étapes à suivre

- Set up une VM
- Installer un hyperviseur pour pouvoir lancer des VMs dans la VM (l'option 'Enable Nested Paging' de la VM hôte doit être cochée pour permettre la nested virtualization).
- Installer **Vagrant**

Le projet a pour but de découvrir **K3s** avec **Vagrant** puis **K3d**.

---

<details>
  <summary>Vagrant</summary>
  <br>

  <u>Qu'est-ce que Vagrant ?</u>

  Vagrant est un outil open-source qui permet de **déployer et gérer des machines virtuelles de manière reproductible**.  
  Il facilite la création d’environnements de développement isolés et identiques sur différents systèmes.  
  Grâce à Vagrant, on peut automatiser la configuration des VM, installer des logiciels et partager des environnements facilement.

  <br>

  <u>Problème récurrent :</u>

  - Par défaut, il peut y avoir un gestionnaire de VM déjà installé sur votre machine.
  - Vérifiez avec la commande :  
    ```bash
    lsmod | grep kvm
    ```
  - Si des modules KVM sont présents, supprimez-les avant de continuer :  
    ```bash
    sudo rmmod kvm_intel
    sudo rmmod kvm
    ```

  <br>

  <u>Documentation officielle :</u> https://developer.hashicorp.com/vagrant/docs

</details>

---

<details>
<summary>Qu'est-ce que k3s ?</summary>
<br>

K3s est une version **simplifiée et allégée de Kubernetes**, conçue pour être simple à déployer et consommer peu de ressources.
Idéal pour des environnements de test ou des machines avec peu de puissance.

<br>
<u>Documentation officielle :</u> https://docs.k3s.io/


</details>

---

<details>
<summary>Qu'est-ce que k3d ?</summary>
<br>

k3d est un **outil qui permet de faire tourner k3s dans des conteneurs Docker**.  

Il est très pratique pour :

- Tester rapidement des clusters Kubernetes localement  
- Automatiser la création de clusters pour le développement  
- Déployer plusieurs clusters isolés sur la même machine  

**Caractéristiques principales :**

- Utilise Docker pour exécuter des clusters k3s  
- Création rapide de clusters multi-nœuds  
- Simple à intégrer dans des pipelines CI/CD  

En résumé, k3d est **k3s dans Docker**, parfait pour expérimenter ou développer localement sans installer Kubernetes complet.

<br>
<u>Documentation officielle :</u> https://k3d.io/stable/

</details>

