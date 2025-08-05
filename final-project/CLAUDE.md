# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DevOps final project implementing a complete CI/CD pipeline with GitOps. The architecture includes:

- **Django application** containerized and deployed to EKS
- **Jenkins CI/CD pipeline** using Kaniko for Docker builds
- **Argo CD** for GitOps-based deployment
- **Terraform modules** for AWS infrastructure provisioning
- **Helm charts** for Kubernetes application deployment

## Infrastructure Architecture

The project uses a modular Terraform approach with the following components:

### Core Infrastructure
- **VPC Module** (`modules/vpc/`): Custom VPC with public/private subnets across AZs
- **EKS Module** (`modules/eks/`): Kubernetes cluster with OIDC provider for IRSA
- **ECR Module** (`modules/ecr/`): Container registry for Docker images
- **RDS Module** (`modules/rds/`): Unified module supporting both RDS and Aurora PostgreSQL
- **S3 Backend Module** (`modules/s3-backend/`): Terraform state backend with DynamoDB locking

### CI/CD Components
- **Jenkins Module** (`modules/jenkins/`): Deployed via Helm with ECR permissions and GitHub integration
- **Argo CD Module** (`modules/argo_cd/`): GitOps controller with auto-sync enabled

## Common Commands

### Terraform Operations
```bash
# Initialize and apply infrastructure
terraform init
terraform plan
terraform apply

# Destroy infrastructure
terraform destroy
```

### EKS Cluster Access
```bash
# Configure kubectl for EKS cluster
aws eks update-kubeconfig --region eu-north-1 --name goit-homework-eks-cluster

# Verify cluster connection
kubectl get nodes
```

### Jenkins Access
```bash
# Get Jenkins LoadBalancer URL
kubectl get services -n jenkins

# Get Jenkins admin password (default: admin123)
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
```

### Argo CD Access
```bash
# Get Argo CD LoadBalancer URL
kubectl get services -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Application Monitoring
```bash
# Check Django application status
kubectl get applications -n argocd
kubectl get pods -n default
kubectl get services django-app

# View application logs
kubectl logs -f deployment/django-app

# Check HPA status
kubectl get hpa
```

## Key Configuration Details

### Jenkins Pipeline
- Uses **Kaniko** for building Docker images without Docker daemon
- Builds images from `django/Dockerfile`
- Pushes to ECR registry: `02125625332.dkr.ecr.eu-north-1.amazonaws.com`
- Auto-updates Helm chart `values.yaml` with new image tags
- Commits changes to trigger Argo CD sync

### RDS Module Usage
The RDS module supports both standard RDS and Aurora configurations:

**Standard RDS (current setup):**
```hcl
module "rds" {
  source = "./modules/rds"
  use_aurora = false
  engine = "postgres"
  engine_version = "17.2"
  instance_class = "db.t3.medium"
  # ... other parameters
}
```

**Aurora Cluster:**
```hcl
module "rds" {
  source = "./modules/rds"
  use_aurora = true
  engine_cluster = "aurora-postgresql"
  aurora_instance_count = 2
  # ... other parameters
}
```

### GitOps Workflow
1. Code changes trigger Jenkins pipeline
2. Jenkins builds and pushes Docker image to ECR
3. Jenkins updates Helm chart values with new image tag
4. Argo CD detects Git changes and syncs application
5. Application is automatically deployed to EKS

## Troubleshooting Commands

### Jenkins Issues
```bash
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller
kubectl describe serviceaccount jenkins-sa -n jenkins
```

### Argo CD Issues
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
kubectl describe application django-app -n argocd
```

### Manual Sync Operations
```bash
# Force Argo CD application sync
kubectl patch application django-app -n argocd --type merge --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## Important Notes

- EKS cluster name: `goit-homework-eks-cluster`
- ECR repository: `goit-devops-homework`
- Django app runs with 2 replicas and HPA (2-10 pods)
- Database is publicly accessible for development (configured in main.tf)
- Jenkins uses service account `jenkins-sa` with ECR permissions via IRSA