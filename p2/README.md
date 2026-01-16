Le but du 2e exo est de créer une vm, donc un node dans laquel on lancera 3 apps différentes avec 
- un pod pour app1
- trois pods pour app2
- un pod pour app1

Vagrantfile

sync_folder monte un volume partagé entre le local et la vm
server.vm.network :private_network, ip: "192.168.56.110" -> donne une ip fixe à la vm (dans un réseau privé donc accessible que depuis le local et les autres vm construite depuis ce local)

Lorsque l'on lance la vm, le script qui s'execute c'est server.sh
-> on installe et lance k3s avec curl -sfL https://get.k3s.io | sh -

-> on créer le dossier /root/.kube
-> on copie y copie le contenu de cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
-> on donne les droits de lecture/écriture à root

kubectl c'est l'outils de ligne de commande
pour fonctionner il a besoin de savoir :
-> ou est le cluster (IP + port)
-> comment s'authentifier (certificats)
-> quel cluster utiliser
toutes ces infos sont présentes dans le file kubeconfig.yml

kubectl cherche son fichier de config par défault dans /root/config
MAIS k3s le créer par défault dans etc/rancher/k3s/k3s.yaml

doucle sécu avec la variable d'env exportée

ensuite on teste kubectl get nodes juste pour être sûre que la cli soit fonctionnelle avant d'utiliser les commandes qu'on veut vraiment lancer
car kubernetes démarre lentement
l'api server n'est pas encore prête donc tester jusqu'à ce que se soit bon

les config maps
-> un object kubernetes qui stocke des fichiers (en l'occurence nos index.html)
-> create echoue si la configmap existe deja
-> --dry-run

-> les pods vont monter ces configs maps

Sans ConfigMap :
nginx → page par défaut

Avec ConfigMap :
nginx → /usr/share/nginx/html → ton index.html


deploy.yml

le spec du deployment 
-> replicas -> je dis combien je veux de pods
-> le template décrit le pod "type", chaque replicas sera un pod basé sur ce template
-> volumeMount déclare le point de montage cad ou on veut monter le voulme
-> le volume est alimenté par la config map
-> important les lablels doivent mathcer celui du deployment

service.yml

le service c'est la partie réseau stable vers les pods
k8s attribue aux pods une ip interne éphémère 
le service créer une ip stable et un nom dns interne pour les pods selectionnés
il fait aussi du load balancing si plusieurs pods correspondent au selector

donc le service abstrait le réseau des pods

-> le selector du service doit matcher le label du deployment pour pouvoir atteindre les pods
-> creation d'un objet service lié au deployment via selector
-> definition du port interne et du port du pod cible 
-> type clusterIP = acessible que depuis le cluster
-> pour exposer au reste du monde nodePort ou load balancer

ingress.yml

c'est la couche d'accès http externe
-> l'ingress agit comme un routeur http pour exposer plusieurs services à l'exterieur
-> il fonctionne toujours avec un ingress controller qui fait le vrai travail de proxy et load balancing

-> type d'objet = ingress
-> ingress controller recoit une requete vers un host, et un path, il regarde la rule correspondante
-> la requete est transmise au service via le name

un service expose des pods à l'échelle du cluster
l'ingress rend des services accessibles depuis l'extérieur du cluster via http/s

-> le target port c'est le port sur lequel l'application écoute dans le pod
-> port c'est le port exposé par le service lui même

ports:
- port: 80        # ce que le client utilise
  targetPort: 3000 # ce que le pod écoute

Client interne
   ↓
app1-service:80   (port)
   ↓
Pod:3000          (targetPort)

backend:
  service:
    name: app1-service
    port:
      number: 80

Ingress → app1-service:80
