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

---

<details>
<summary>Configuration initiale de la VM</summary>
<br>

<u>1. Redimensionner l'écran (Guest Additions)</u>

Installer les dépendances puis les Guest Additions VirtualBox :

```bash
sudo apt update
sudo apt install build-essential dkms linux-headers-$(uname -r)
```

Dans le menu VirtualBox : **Périphériques → Insérer l'image CD des Additions invité...**

```bash
sudo mount /dev/cdrom /mnt
sudo /mnt/VBoxLinuxAdditions.run
sudo reboot
```

<u>2. Configurer le clavier en AZERTY</u>

```bash
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'fr')]"
```

<u>3. Configurer une clé SSH pour GitHub</u>

```bash
ssh-keygen -t ed25519 -C "ton-email@example.com"
cat ~/.ssh/id_ed25519.pub
```

Copier la clé publique sur GitHub : **Settings → SSH and GPG keys → New SSH key**

Tester la connexion :

```bash
ssh -T git@github.com
```

<u>4. Set up Vagrant</u>

```bash
# Installer les prérequis
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Ajouter la clé GPG et le dépôt HashiCorp
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Installer Vagrant
sudo apt update
sudo apt install -y vagrant
```

</details>

