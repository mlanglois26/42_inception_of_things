Le but du premier exo est de lancer deux VMs. 
-> dans la vm server, on installe kubernetes et on y place de master node / control plan
-> dans la vm agent, on installe kubernetes et on y place un worker node qui sera rattaché au master node de la vm server

La cli pour run le Vagrantfile est vagrant up
-> ça va créer les deux vms en s'appuyant sur leurs configs

Dans la vm server, on execute le script server.sh
-> avec cette cli : curl -sfL https://get.k3s.io | sh -
-> on installe kubernetes (k3s qui est une version légère de kubernetes)
-> on démarre le service k3s

Lors du démarrage de k3s, un  node token est généré. Il est stocké dans /var/lib/rancher/k3s/server/node-token
-> donc dans la boucle while du script on attend que le token soit généré
-> on va ensuite copié ce token dans /vagrant/token car c'est un dossier partagé Vagrant. Il est monté automatiquement entre la vm et la machine hôte
-> on /vagrant/token lisible par tout le monde et on donne les droits d'écriture à root

Le token permet à un node agent de rejoindre le cluster
Le but est donc de rendre le token accessible pour permettre au worker node de rejoindre le cluster du master node.

Dans la vm agent, on execute le script agent.sh
-> on attend que le token généré depuis la vm server par le master node soit copié dans le dossier vagrant accessible par tous
-> on curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${TOKEN} sh -
-> donc on installe kubernetes 
-> on démarre k3s en lui passant l'IP de la vm server et le token du master node

Le worker node qui existe dans la vm agent est donc bien connecté au master node qui se trouve dans la vm server 
