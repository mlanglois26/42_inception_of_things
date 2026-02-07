# 42_inception_of_things

Le but de ce projet est de manipuler des machines virtuelles en local avec **Vagrant** et de se familiariser avec **Kubernetes** à travers **k3s** et **k3d**.

---

<details>
<summary><strong>Vagrant</strong></summary>

### Qu'est-ce que Vagrant ?

Vagrant est un outil open-source qui permet de **déployer et gérer des machines virtuelles de manière reproductible**.
Il facilite la création d'environnements de développement isolés et identiques sur différents systèmes.
Grâce à Vagrant, on peut automatiser la configuration des VM, installer des logiciels et partager des environnements facilement.

**Documentation officielle :** <https://developer.hashicorp.com/vagrant/docs>

</details>

---

<details>
<summary><strong>k3s</strong></summary>

### Qu'est-ce que k3s ?

k3s est une version **simplifiée et allégée de Kubernetes**, conçue pour être simple à déployer et consommer peu de ressources.
C'est idéal pour des environnements de test ou des machines avec peu de puissance.

**Documentation officielle :** <https://docs.k3s.io/>

</details>

---

<details>
<summary><strong>k3d</strong></summary>

### Qu'est-ce que k3d ?

k3d est un **outil qui permet de faire tourner k3s dans des conteneurs Docker**.

Il est très pratique pour :

- Tester rapidement des clusters Kubernetes localement
- Automatiser la création de clusters pour le développement
- Déployer plusieurs clusters isolés sur la même machine

**Caractéristiques principales :**

- Il utilise Docker pour exécuter des clusters k3s
- Il permet la création rapide de clusters multi-noeuds
- Il est simple à intégrer dans des pipelines CI/CD

En résumé, k3d est **k3s dans Docker**, parfait pour expérimenter ou développer localement sans installer Kubernetes complet.

**Documentation officielle :** <https://k3d.io/stable/>

</details>

---

<details>
<summary><strong>Configuration de la VM mère</strong></summary>

### Présentation

L'ensemble du projet tourne dans une **VM Ubuntu** créée à partir de **VirtualBox**. C'est la machine hôte dans laquelle on installe Vagrant, on lance les clusters k3s/k3d et on exécute toutes les commandes du projet.

### 1. Activer la nested virtualization (VT-x)

Pour pouvoir utiliser KVM/libvirt à l'intérieur de la VM, il faut activer la **Nested VT-x/AMD-V** dans les paramètres VirtualBox de la VM mère. Cette option expose les instructions de virtualisation matérielle au système invité.

On peut le faire via l'interface graphique : **Système > Processeur > Cocher "Activer VT-x/AMD-V imbriqué"**

Ou via la ligne de commande sur la machine hôte (VM éteinte) :

```bash
VBoxManage.exe modifyvm "nom_de_la_vm" --nested-hw-virt on
```

### 2. Redimensionner l'écran (Guest Additions)

On installe les dépendances puis les Guest Additions VirtualBox :

```bash
sudo apt update
sudo apt install build-essential dkms linux-headers-$(uname -r)
```

Dans le menu VirtualBox : **Périphériques > Insérer l'image CD des Additions invité...**

```bash
sudo mount /dev/cdrom /mnt
sudo /mnt/VBoxLinuxAdditions.run
sudo reboot
```

### 3. Configurer le clavier en AZERTY

```bash
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'fr')]"
```

### 4. Configurer une clé SSH pour GitHub

```bash
ssh-keygen -t ed25519 -C "email@example.com"
cat ~/.ssh/id_ed25519.pub
```

On copie ensuite la clé publique sur GitHub : **Settings > SSH and GPG keys > New SSH key**

On peut tester la connexion avec :

```bash
ssh -T git@github.com
```

### 5. Installer Vagrant

```bash
# Installation des prérequis
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Ajout de la clé GPG et du dépôt HashiCorp
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Installation de Vagrant
sudo apt update
sudo apt install -y vagrant
```

### 6. Problème récurrent : modules KVM

Par défaut, il peut y avoir un gestionnaire de VM déjà installé sur la machine. Les modules KVM peuvent entrer en conflit avec VirtualBox.

On vérifie avec la commande suivante :

```bash
lsmod | grep kvm
```

Si des modules KVM sont présents, on les supprime avant de continuer :

```bash
sudo rmmod kvm_intel
sudo rmmod kvm
```

</details>

---

<details>
<summary><strong>Configuration des VM filles (KVM / libvirt)</strong></summary>

### Pourquoi KVM et pas VirtualBox ?

Les VM filles (créées par Vagrant) n'utilisent pas VirtualBox mais **KVM/libvirt**. En contexte de nested virtualization (VM mère > VM filles), le choix du provider a un impact direct sur les performances :

- **VirtualBox** est un hyperviseur de type 2 (logiciel complet au-dessus de l'OS). En nested, cela crée une double couche de virtualisation, ce qui est souvent très lent.
- **KVM** est intégré directement au **noyau Linux**. Il est donc beaucoup plus proche du matériel et bien plus performant en nested virtualization.

```
Hôte physique (VT-x activé)
└── VM mère (Ubuntu / VirtualBox)
    ├── VirtualBox (type 2) → double couche, lent
    └── KVM (noyau Linux)   → une seule couche, rapide
```

### Vagrant, libvirt, QEMU, KVM : qui fait quoi ?

```
Vagrant
└── vagrant-libvirt (plugin)
    └── libvirt (API / daemon)
        └── QEMU + KVM (virtualisation)
```

| Composant | Rôle |
|-----------|------|
| **KVM** | Module du **noyau Linux**. Il transforme Linux en hyperviseur en utilisant les instructions CPU (VT-x). C'est lui qui fait tourner la VM à quasi-vitesse native. |
| **QEMU** | **Émulateur matériel**. Il simule le hardware (carte réseau, disque, écran...) pour la VM. Sans KVM, QEMU émule tout (lent). Avec KVM, QEMU délègue le CPU au noyau et ne gère que le reste. |
| **libvirt** | **API / daemon** (`libvirtd`). Couche d'abstraction qui pilote QEMU/KVM via une interface unifiée. `virsh`, `virt-manager` et le plugin Vagrant l'utilisent. |
| **Vagrant** | **Orchestrateur CLI**. Il ne virtualise rien lui-même. Il appelle un **provider** (VirtualBox, libvirt, Docker...) pour créer/gérer les VM. Il gère aussi le provisioning (scripts), le réseau, les synced folders, SSH, etc. |

### Installation (KVM / libvirt)

Prérequis sur la VM mère (Ubuntu/Debian) :

```bash
sudo apt-get update
sudo apt-get install -y libvirt-dev libvirt-daemon-system qemu-kvm
vagrant plugin install vagrant-libvirt
```

On peut ajouter l'utilisateur au groupe `libvirt` puis se reconnecter (ou `newgrp libvirt`) :

```bash
sudo usermod -aG libvirt $USER
```

On récupère la box (une seule fois) puis on lance la VM :

```bash
vagrant box add generic/debian12 --provider libvirt   # une seule fois
vagrant up --provider=libvirt
```

Pour ne pas avoir à préciser `--provider=libvirt` à chaque fois, on peut définir le provider par défaut :

```bash
export VAGRANT_DEFAULT_PROVIDER=libvirt
```

On peut ajouter cette ligne dans le `~/.bashrc` pour que ce soit permanent.

</details>
