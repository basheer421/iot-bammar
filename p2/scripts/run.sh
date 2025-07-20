#!/bin/bash

sudo apt update
sudo apt install -y curl
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address=192.168.56.110 --flannel-iface=eth1" sh -
cp /vagrant/scripts/three_app.yaml /vagrant/
sudo kubectl apply -f /vagrant/three_app.yaml
