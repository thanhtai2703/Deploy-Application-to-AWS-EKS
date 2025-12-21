#!/bin/bash

echo "🚀 Starting ArgoCD Installation..."

# 1. Create Namespace
echo "Creating namespace 'argocd'..."
kubectl create namespace argocd 2>/dev/null || echo "Namespace 'argocd' already exists."

# 2. Install ArgoCD
echo "Installing ArgoCD manifests..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD server to be ready
echo "Waiting for ArgoCD server to be ready (this may take a minute)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Expose ArgoCD via LoadBalancer
echo "Exposing ArgoCD server via LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 5. Retrieve Access Information
echo "------------------------------------------------------------"
echo "✅ ArgoCD Installation Complete!"
echo "------------------------------------------------------------"

# Get Password
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Username: admin"
echo "Password: $PASS"

# Get URL (Wait for LB to provision)
echo "Waiting for LoadBalancer URL..."
sleep 10
URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "URL: http://$URL"
echo "------------------------------------------------------------"
echo "NOTE: It may take 2-3 minutes for the LoadBalancer URL to become active in your browser."
