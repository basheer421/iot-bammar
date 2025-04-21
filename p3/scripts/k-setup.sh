#!/bin/bash

k3d cluster create mycluster

kubectl create namespace dev
kubectl create namespace argocd

# From official repo
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# To not use -n dev everytime - set default namespace context
kubectl config set-context --current --namespace=dev

