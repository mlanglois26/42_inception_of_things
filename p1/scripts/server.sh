#!/bin/bash
set -e

SERVER_IP="192.168.56.110"

rm -f /vagrant/token

echo "[SERVER] Installation de k3s server..."

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  --node-ip ${SERVER_IP} \
  --advertise-address ${SERVER_IP} \
  --tls-san ${SERVER_IP}" sh -

echo "[SERVER] Attente du token..."
while [[ ! -f /var/lib/rancher/k3s/server/node-token ]]; do
  sleep 1
done

echo "[SERVER] Copie du token dans /vagrant/token"
cp /var/lib/rancher/k3s/server/node-token /vagrant/token
chmod 644 /vagrant/token

echo "[SERVER] k3s server prêt ✅"
