#!/bin/bash
set -e

# set -e to make the script fail early

if k3d cluster get mycluster >/dev/null 2>&1; then
    echo "Cluster 'mycluster' exists. Recreating..."
    k3d cluster delete mycluster
else
    echo "Cluster 'mycluster' does not exist. Creating..."
fi

k3d cluster create mycluster

kubectl create namespace dev
kubectl create namespace argocd

echo Applying argocd...
# From official repo
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo Waiting for Argo CD admin secret to be created...
until kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; do
  sleep 2
done

echo Gettng argocd password...
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

# To not use -n dev everytime - set default namespace context
kubectl config set-context --current --namespace=dev

echo Applyig Dev project
kubectl apply -f ../confs/conf.yml

echo Opening port 8080 for argocd login...
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
PF_PID=$!
sleep 5 # To make sure the port is opened

# Trap to kill port-forward on script exit or interrupt
trap "kill $PF_PID" EXIT

echo Loging in to argocd
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure

echo 'Creating argocd app from (https://github.com/basheer421/iot-bammar.git)...'
argocd app create my-app \
  --repo https://github.com/basheer421/iot-bammar.git \
  --path p3/confs \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

echo Syncing the app with argocd...
argocd app sync my-app

echo Waiting for app to become synced and healthy...
argocd app wait my-app --sync --health --timeout 60

