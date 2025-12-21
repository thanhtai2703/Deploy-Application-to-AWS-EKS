#!/bin/bash

# Navigate to Terraform directory
cd EKS-TF

echo "Reading Terraform outputs..."
ROLE_ARN=$(terraform output -raw alb_role_arn)
VPC_ID=$(terraform output -raw vpc_id)
CLUSTER_NAME=$(terraform output -raw cluster_name)

if [ -z "$ROLE_ARN" ] || [ -z "$VPC_ID" ] || [ -z "$CLUSTER_NAME" ]; then
    echo "Error: Could not retrieve outputs from Terraform. Did you run 'terraform apply'?"
    exit 1
fi

echo "Found configuration:"
echo "  Cluster: $CLUSTER_NAME"
echo "  VPC ID:  $VPC_ID"
echo "  Role ARN: $ROLE_ARN"

# Return to root
cd ..

# Add Helm Repo
echo "Updating Helm repositories..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install CRDs (Direct YAML to avoid kustomize errors on Windows)
echo "Installing CRDs..."
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml

# Install Controller
echo "Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN \
  --set region=us-east-1 \
  --set vpcId=$VPC_ID

if [ $? -eq 0 ]; then
    echo "✅ Controller installed successfully!"
else
    echo "❌ Installation failed."
fi
