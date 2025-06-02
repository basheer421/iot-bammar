#!/bin/bash
set -e

# set -e to make the script fail early

if k3d cluster get mycluster >/dev/null 2>&1; then
    echo "Cluster 'mycluster' exists. Recreating..."
    k3d cluster delete mycluster
else
    echo "Cluster 'mycluster' does not exist. Creating..."
fi

k3d cluster create mycluster --port 30080:30080@loadbalancer --port 8888:80@loadbalancer

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

echo "Opening a NodePort 30080 service for argocd..."
kubectl patch svc argocd-server -n argocd -p '{
  "spec": {
    "type": "NodePort",
    "ports": [{
      "port": 443,
      "targetPort": 8080,
      "nodePort": 30080,
      "protocol": "TCP"
    }]
  }
}'

# To not use -n dev everytime - set default namespace context
kubectl config set-context --current --namespace=dev

echo "Installing Ingress NGINX (baremetal variant)..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

echo "Waiting for Ingress NGINX controller pod to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=60s

echo "Waiting for Ingress webhook service to have endpoints..."
until kubectl get endpoints ingress-nginx-controller-admission -n ingress-nginx -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .; do
  echo "Waiting for ingress-nginx-controller-admission endpoints..."
  sleep 2
done

echo Applyig Dev project
kubectl apply -f ../confs/conf.yml

echo Ensuring argocd is ready for logging in...
kubectl wait deployment argocd-server -n argocd --for=condition=Available=True --timeout=60s

echo Loging in to argocd
argocd login localhost:30080 --username admin --password "$ARGOCD_PASSWORD" --insecure

echo 'Creating argocd app from (https://github.com/basheer421/iot-bammar.git)...'
argocd app create iot \
  --repo https://github.com/basheer421/iot-bammar.git \
  --path p3/confs \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

argocd app set iot --sync-policy automated --self-heal --allow-empty

echo Syncing the app with argocd...
argocd app sync iot

echo Waiting for app to become synced and healthy...
argocd app wait iot --sync --health --timeout 60

echo Applying pod to watch changes every 10 seconds
kubectl apply -n argocd -f ../confs/refresher.yml

echo Your login:
echo ---------------
echo Username: admin
echo Password: $ARGOCD_PASSWORD
echo ---------------
