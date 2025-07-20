#!/bin/bash

K3S_TOKEN="/vagrant/confs/server_token.txt"
# hhttps://docs.k3s.io/networking/basic-network-options#flannel-agent-options
curl -L https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN_FILE=${K3S_TOKEN}  INSTALL_K3S_EXEC="--flannel-iface=eth1" sh -
sudo rm -rf /vagrant/confs/*
