Prerequisites
Ensure you have these installed and configured:

- AWS CLI (aws configure with your credentials).
- Terraform (v1.3+).
- Kubectl.
- Helm.
- Git Bash (Recommended for Windows to run .sh scripts) or a Linux terminal.

---

Phase 1: Infrastructure Provisioning
Create the S3 bucket for state, then the EKS cluster, VPC, and Nodes.

1.  Bootstrap Remote Backend (One-time only):
    1 cd EKS-TF/backend-setup
    2 terraform init
    3 terraform apply --auto-approve
    (Creates S3 bucket `todo-terraform-state-...` and DynamoDB table).

2.  Provision EKS Cluster:
    1 cd ../ # Go back to EKS-TF root
    2 terraform init
    3 terraform apply -var-file="variables.tfvars" --auto-approve
    (Wait ~15-20 mins. This sets up EKS, OIDC, and IAM roles).

3.  Connect `kubectl` to Cluster:

1 aws eks update-kubeconfig --region us-east-1 --name ToDo-EKS-Cluster

---

Phase 2: Install Kubernetes Controllers
Install the AWS Load Balancer Controller so your Ingress works.

1.  Run Installation Script:
    1 cd .. # Go back to project root
    2 bash install_alb.sh
    (This installs the controller using Helm and links it to the Terraform IAM role).

---

Phase 3: CI/CD Setup (GitHub)
Configure GitHub to build your Docker images automatically.

1.  Add Repository Secrets:
    Go to Settings > Secrets and variables > Actions and add:

    - DOCKER_USERNAME: Your Docker Hub username.
    - DOCKER_PASSWORD: Your Docker Hub password/token.
    - GIT_TOKEN: A GitHub Personal Access Token (repo scope) to allow the pipeline to commit changes.

2.  Trigger Build:
    Commit and push your code to the main branch.
    1 git add .
    2 git commit -m "Initial Deploy"
    3 git push origin main
    _ Wait for the "Microservices Build & Deploy" Action to finish (Green ✅).
    _ Why? The pipeline updates the YAML files in K8s/ with the correct image tags.

---

Phase 4: Deploy Applications
Deploy the Database and Services to the cluster.

1.  Pull Latest Manifests:
    Since the pipeline updated your YAML files, pull them down:
    1 git pull origin main

2.  Create Namespaces & Storage Class:

1 kubectl apply -f K8s/namespaces.yml
2 kubectl apply -f K8s/storage-class.yml

3.  Deploy Database (StatefulSet):
    1 kubectl apply -f K8s/postgres.yml
    Wait for it to run: kubectl get pods -n databases -w

4.  Deploy Backend & Frontend:
    1 kubectl apply -f K8s/

---

Phase 5: Access the Application

1.  Get the URL:
    1 kubectl get ingress -n prod
    Copy the ADDRESS (e.g., `k8s-prod-todoingr-xxxx.us-east-1.elb.amazonaws.com`).

2.  Open in Browser:
    Paste the address. You should see the Todo App.

    - Test: Create a new user, then login and create a Todo task.
    - Stats: Visit /stats to see the analytics dashboard.
