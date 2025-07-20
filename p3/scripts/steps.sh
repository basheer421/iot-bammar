#!/bin/bash

# Enforce sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo or as root." >&2
   exit 1
fi

# Install docker
curl -fsSL https://get.docker.com | sh -
sudo usermod -aG docker bush

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# argocd 
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Reboot for docker rootless
echo "Rebooting for docker rootless mode"
sleep 2

read -p "Do you want to reboot now? (y/n): " answer

case "$answer" in
    [Yy]* ) reboot;;
    * ) exit 1;;
esac
