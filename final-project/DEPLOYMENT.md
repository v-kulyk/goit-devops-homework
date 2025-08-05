# GoIT DevOps Final Project - Deployment Guide

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [AWS Setup](#aws-setup)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Component Verification](#component-verification)
- [Accessing Services](#accessing-services)
- [Monitoring Setup](#monitoring-setup)
- [Troubleshooting](#troubleshooting)
- [Cost Management](#cost-management)
- [Cleanup Instructions](#cleanup-instructions)

## Architecture Overview

This project implements a complete CI/CD pipeline with GitOps using the following components:

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────────┐ │
│  │     VPC     │    │     ECR      │    │         S3          │ │
│  │   3 AZs     │    │  Container   │    │   Terraform        │ │
│  │Public/Priv  │    │  Registry    │    │     State          │ │
│  └─────────────┘    └──────────────┘    └─────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    EKS Cluster                              │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Jenkins   │  │   Argo CD   │  │     Monitoring      │ │ │
│  │  │   CI/CD     │  │   GitOps    │  │ Prometheus/Grafana  │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │                Django Application                       │ │ │
│  │  │           Auto-scaling (HPA: 2-10 pods)                │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    RDS PostgreSQL                           │ │
│  │              (Multi-AZ available)                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components:
- **Infrastructure**: VPC with public/private subnets across 3 AZs
- **Container Registry**: ECR for Docker image storage
- **Kubernetes**: EKS cluster with managed node groups
- **CI/CD**: Jenkins with Kaniko for containerized builds
- **GitOps**: Argo CD for automated deployments
- **Database**: RDS PostgreSQL with backup and encryption
- **Monitoring**: Prometheus + Grafana stack
- **State Management**: S3 + DynamoDB for Terraform state

## Prerequisites

### Required Tools
Ensure you have the following tools installed on your local machine:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform (>= 1.0)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Git
sudo apt-get update && sudo apt-get install git -y
```

### Version Verification
```bash
aws --version          # AWS CLI 2.x
terraform --version    # >= 1.0
kubectl version --client
helm version
git --version
```

### AWS Account Requirements
- AWS Account with administrative access
- Programmatic access (Access Key ID + Secret Access Key)
- Available service limits:
  - VPC: 1 (default: 5)
  - EKS Clusters: 1 (default: 100)
  - EC2 Instances: 3-5 (default: 20)
  - RDS Instances: 1 (default: 40)

## AWS Setup

### 1. Configure AWS Credentials
```bash
# Method 1: AWS CLI Configure
aws configure
# Enter your Access Key ID, Secret Access Key, Region (eu-north-1), and output format (json)

# Method 2: Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-north-1"

# Method 3: AWS Credentials File
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
EOF

cat > ~/.aws/config << EOF
[default]
region = eu-north-1
output = json
EOF
```

### 2. Verify AWS Access
```bash
# Test AWS connectivity
aws sts get-caller-identity
aws ec2 describe-regions --region eu-north-1

# Check available AZs in eu-north-1
aws ec2 describe-availability-zones --region eu-north-1
```

### 3. Create GitHub Personal Access Token
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token with permissions:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
   - `admin:repo_hook` (Full control of repository hooks)
3. Copy the token for later use

## Step-by-Step Deployment

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone <your-repository-url>
cd final-project

# Create terraform.tfvars from template
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

### Step 2: Configure Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# Required: Replace with your values
aws_region = "eu-north-1"
bucket_name = "your-unique-bucket-name-here"  # Must be globally unique
github_username = "your-github-username"
github_token = "your-github-token"
postgres_password = "your-secure-password"

# Optional: Customize as needed
availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
vpc_name = "goit-homework-vpc"
ecr_name = "goit-devops-homework"
postgres_db = "djangoapp"
postgres_user = "postgres"

# Tags for resource organization
common_tags = {
  Environment = "final-project"
  Project     = "goit-devops-homework"
  Owner       = "your-name"
}
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# Validate configuration
terraform validate

# Plan deployment (review what will be created)
terraform plan
```

### Step 4: Deploy Infrastructure

```bash
# Apply configuration (this will take 15-20 minutes)
terraform apply

# Review the plan and type 'yes' to proceed
# Expected resources to be created: ~50-70 resources
```

### Step 5: Configure kubectl

```bash
# Update kubeconfig to access EKS cluster
aws eks update-kubeconfig --region eu-north-1 --name goit-homework-eks-cluster

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

## Component Verification

### 1. Infrastructure Verification

```bash
# Verify VPC and subnets
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=goit-homework-vpc"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Verify EKS cluster
aws eks describe-cluster --name goit-homework-eks-cluster --region eu-north-1
kubectl get nodes -o wide

# Verify ECR repository
aws ecr describe-repositories --repository-names goit-devops-homework --region eu-north-1

# Verify RDS instance
aws rds describe-db-instances --region eu-north-1
```

### 2. Kubernetes Services Verification

```bash
# Check all namespaces
kubectl get namespaces

# Verify Jenkins deployment
kubectl get pods -n jenkins
kubectl get services -n jenkins

# Verify Argo CD deployment
kubectl get pods -n argocd
kubectl get services -n argocd

# Verify monitoring stack
kubectl get pods -n monitoring
kubectl get services -n monitoring

# Check persistent volumes
kubectl get pv
kubectl get pvc -A
```

### 3. Application Health Checks

```bash
# Jenkins health check
kubectl exec -n jenkins deployment/jenkins -- curl -f http://localhost:8080/login

# Argo CD health check
kubectl exec -n argocd deployment/argocd-server -- curl -f http://localhost:8080/healthz

# Prometheus health check
kubectl exec -n monitoring deployment/prometheus-server -- curl -f http://localhost:9090/-/healthy

# Grafana health check
kubectl exec -n monitoring deployment/grafana -- curl -f http://localhost:3000/api/health
```

## Accessing Services

### Port Forwarding Commands

#### Jenkins (Port 8080)
```bash
# Forward Jenkins to localhost:8080
kubectl port-forward -n jenkins svc/jenkins 8080:80

# Get Jenkins admin password
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password

# Access: http://localhost:8080
# Username: admin
# Password: (from above command)
```

#### Argo CD (Port 8081)
```bash
# Forward Argo CD to localhost:8081
kubectl port-forward -n argocd svc/argocd-server 8081:80

# Get Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access: http://localhost:8081
# Username: admin
# Password: (from above command)
```

#### Grafana (Port 3000)
```bash
# Forward Grafana to localhost:3000
kubectl port-forward -n monitoring svc/grafana 3000:80

# Get Grafana admin password (default: admin123)
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Access: http://localhost:3000
# Username: admin
# Password: admin123 (or from above command)
```

#### Prometheus (Port 9090)
```bash
# Forward Prometheus to localhost:9090
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Access: http://localhost:9090
```

### External Access (Alternative)

If you prefer external LoadBalancer access:

```bash
# Get external IPs (may take a few minutes to provision)
kubectl get services -n jenkins
kubectl get services -n argocd
kubectl get services -n monitoring

# Watch for EXTERNAL-IP to be assigned
kubectl get services -n monitoring -w
```

## Monitoring Setup

### Grafana Dashboard Configuration

1. **Access Grafana** via port-forward or external IP
2. **Login** with admin credentials
3. **Verify Data Source**: 
   - Go to Configuration → Data Sources
   - Confirm Prometheus is configured: `http://prometheus-server:80`

4. **Import Additional Dashboards**:
   ```
   Dashboard ID: 7249 - Kubernetes Cluster Monitoring
   Dashboard ID: 1860 - Node Exporter Full
   Dashboard ID: 6417 - Kubernetes Pods
   Dashboard ID: 8588 - Kubernetes Deployment
   ```

### Custom Metrics for Django App

Add to your Django application:

```python
# In your Django settings.py or dedicated metrics app
from prometheus_client import Counter, Histogram, generate_latest
import time

# Metrics
REQUEST_COUNT = Counter('django_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('django_request_duration_seconds', 'Request latency')

# In your middleware or views
REQUEST_COUNT.labels(method='GET', endpoint='/api/health').inc()

# Metrics endpoint
def metrics_view(request):
    return HttpResponse(generate_latest(), content_type='text/plain')
```

Add annotations to your Django deployment:

```yaml
# In your Kubernetes deployment
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8000"
    prometheus.io/path: "/metrics"
```

### Alerting Rules

Create custom alerting rules in `monitoring/alerts.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-alerts
  namespace: monitoring
data:
  alerts.yaml: |
    groups:
    - name: django-app
      rules:
      - alert: DjangoAppDown
        expr: up{job="django-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Django application is down"
          
    - name: kubernetes
      rules:
      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.node }} is not ready"
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Terraform Issues

**Issue**: `bucket_name` already exists
```bash
# Solution: Use a unique bucket name
sed -i 's/your-unique-bucket-name-here/your-name-$(date +%s)/g' terraform.tfvars
```

**Issue**: AWS credentials not found
```bash
# Solution: Verify AWS configuration
aws sts get-caller-identity
aws configure list
```

**Issue**: Resource limits exceeded
```bash
# Solution: Check and request limit increases
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
```

#### 2. EKS Issues

**Issue**: Unable to connect to EKS cluster
```bash
# Solution: Update kubeconfig and check IAM permissions
aws eks update-kubeconfig --region eu-north-1 --name goit-homework-eks-cluster
kubectl config current-context
kubectl auth can-i get pods --all-namespaces
```

**Issue**: Nodes not joining cluster
```bash
# Solution: Check node group status and security groups
aws eks describe-nodegroup --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group
kubectl get nodes
kubectl describe nodes
```

#### 3. Application Issues

**Issue**: Pods stuck in Pending state
```bash
# Solution: Check resources and node capacity
kubectl describe pod <pod-name> -n <namespace>
kubectl top nodes
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Issue**: ImagePullBackOff errors
```bash
# Solution: Check ECR permissions and image existence
aws ecr describe-images --repository-name goit-devops-homework
kubectl describe pod <pod-name> -n <namespace>
```

#### 4. Jenkins Issues

**Issue**: Jenkins pod fails to start
```bash
# Solution: Check logs and persistent volume
kubectl logs -n jenkins deployment/jenkins
kubectl get pvc -n jenkins
kubectl describe pvc -n jenkins
```

**Issue**: Jenkins can't push to ECR
```bash
# Solution: Verify IRSA permissions
kubectl describe serviceaccount jenkins-sa -n jenkins
aws iam get-role --role-name jenkins-role
```

#### 5. Monitoring Issues

**Issue**: Prometheus not scraping targets
```bash
# Solution: Check service discovery and network policies
kubectl exec -n monitoring deployment/prometheus-server -- wget -qO- http://localhost:9090/api/v1/targets
kubectl get networkpolicies -A
```

**Issue**: Grafana dashboards not loading
```bash
# Solution: Check data source and connectivity
kubectl exec -n monitoring deployment/grafana -- curl -f http://prometheus-server:80/api/v1/query?query=up
```

### Debug Commands

```bash
# General debugging
kubectl get events --sort-by=.metadata.creationTimestamp -A
kubectl get pods -A -o wide
kubectl top nodes
kubectl top pods -A

# Logs
kubectl logs -n jenkins deployment/jenkins --previous
kubectl logs -n argocd deployment/argocd-server -f
kubectl logs -n monitoring deployment/prometheus-server -c prometheus

# Resource usage
kubectl describe node
kubectl get resourcequotas -A
kubectl get limitranges -A

# Networking
kubectl get services -A
kubectl get ingress -A
kubectl get networkpolicies -A
```

## Cost Management

### Expected Monthly Costs (eu-north-1)

| Service | Configuration | Estimated Cost/Month |
|---------|--------------|---------------------|
| EKS Cluster | 1 cluster | $73 |
| EC2 Instances | 2x t2.micro nodes | $17 |
| RDS PostgreSQL | db.t3.medium | $31 |
| ALB/NLB | 2 load balancers | $22 |
| ECR | 1GB storage | $0.10 |
| S3 | State storage | $1 |
| **Total** | | **~$144/month** |

### Cost Optimization Tips

1. **Use Spot Instances** for non-production:
```hcl
# In EKS node group configuration
instance_types = ["t3.medium"]
capacity_type = "SPOT"
```

2. **Auto-scaling Configuration**:
```hcl
# Minimize costs during low usage
desired_capacity = 1
min_capacity = 1
max_capacity = 3
```

3. **Schedule Shutdowns**:
```bash
# Create a script to scale down after hours
kubectl scale deployment --replicas=0 -n jenkins jenkins
kubectl scale deployment --replicas=0 -n argocd argocd-server
```

### Cost Monitoring

```bash
# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# Set up billing alerts (replace with your email)
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget-alert.json
```

Create `budget-alert.json`:
```json
{
  "BudgetName": "EKS-Monthly-Budget",
  "BudgetLimit": {
    "Amount": "200",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST",
  "CostFilters": {
    "Service": ["Amazon Elastic Kubernetes Service", "Amazon Elastic Compute Cloud - Compute"]
  }
}
```

## Cleanup Instructions

### ⚠️ Important: Complete Infrastructure Cleanup

**WARNING**: Ensure complete cleanup to avoid unexpected charges!

### Method 1: Terraform Destroy (Recommended)

```bash
# Navigate to project directory
cd final-project

# Destroy all resources (this may take 10-15 minutes)
terraform destroy

# Confirm by typing 'yes' when prompted
# This will remove ALL resources created by Terraform
```

### Method 2: Manual Cleanup (if Terraform fails)

If `terraform destroy` fails, manually clean up in this order:

#### 1. Delete Kubernetes Resources
```bash
# Delete all applications first
kubectl delete applications -n argocd --all

# Delete Helm releases
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring

# Delete namespaces
kubectl delete namespace jenkins argocd monitoring
```

#### 2. Delete EKS Resources
```bash
# Delete node groups
aws eks delete-nodegroup --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group

# Wait for node group deletion to complete
aws eks wait nodegroup-deleted --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group

# Delete cluster
aws eks delete-cluster --name goit-homework-eks-cluster
```

#### 3. Delete RDS Resources
```bash
# Delete RDS instance (skip snapshot if not needed)
aws rds delete-db-instance \
  --db-instance-identifier djangoapp-db \
  --skip-final-snapshot \
  --delete-automated-backups
```

#### 4. Delete VPC Resources
```bash
# Delete NAT Gateways
aws ec2 describe-nat-gateways --query 'NatGateways[*].NatGatewayId' --output text | xargs -n1 aws ec2 delete-nat-gateway --nat-gateway-id

# Delete Internet Gateway
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=goit-homework-vpc" --query 'Vpcs[0].VpcId' --output text)
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

#### 5. Delete ECR Repository
```bash
# Delete ECR repository and all images
aws ecr delete-repository --repository-name goit-devops-homework --force
```

#### 6. Delete S3 Bucket
```bash
# Empty and delete S3 bucket
BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "your-bucket-name")
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rb s3://$BUCKET_NAME
```

#### 7. Delete DynamoDB Table
```bash
# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-locks
```

### Verification of Cleanup

```bash
# Verify no EKS clusters
aws eks list-clusters

# Verify no RDS instances
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier'

# Verify no ECR repositories
aws ecr describe-repositories

# Verify VPCs (should only show default VPC)
aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`]'

# Check for any remaining EC2 instances
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`]'
```

### Final Cost Check

```bash
# Check current month costs after cleanup
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Emergency Cleanup Script

Create `emergency-cleanup.sh`:
```bash
#!/bin/bash
set -e

echo "🚨 EMERGENCY CLEANUP - This will delete ALL project resources!"
echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
sleep 10

# Terraform destroy
echo "Running terraform destroy..."
terraform destroy -auto-approve || echo "Terraform destroy failed, continuing with manual cleanup..."

# Manual cleanup
echo "Performing manual cleanup..."
kubectl delete namespace jenkins argocd monitoring --ignore-not-found=true

# Delete EKS cluster
aws eks delete-nodegroup --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group || true
aws eks wait nodegroup-deleted --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group || true
aws eks delete-cluster --name goit-homework-eks-cluster || true

# Delete other resources
aws rds delete-db-instance --db-instance-identifier djangoapp-db --skip-final-snapshot --delete-automated-backups || true
aws ecr delete-repository --repository-name goit-devops-homework --force || true

echo "✅ Emergency cleanup completed. Please verify in AWS Console!"
```

### 📞 Support

If you encounter issues:

1. **Check AWS CloudFormation** console for stuck stacks
2. **Review AWS CloudTrail** for detailed error logs
3. **Contact AWS Support** for resource deletion issues
4. **Use AWS CLI** with `--debug` flag for detailed error information

Remember: Complete cleanup is essential to avoid unexpected charges!

---

## Summary

This deployment guide provides comprehensive instructions for deploying a complete DevOps infrastructure with monitoring capabilities. The setup includes:

- ✅ **Infrastructure as Code** with Terraform
- ✅ **Kubernetes orchestration** with EKS
- ✅ **CI/CD pipeline** with Jenkins and Kaniko
- ✅ **GitOps deployment** with Argo CD
- ✅ **Comprehensive monitoring** with Prometheus and Grafana
- ✅ **Database management** with RDS PostgreSQL
- ✅ **Container registry** with ECR
- ✅ **Cost management** and cleanup procedures

Follow the steps carefully, and remember to clean up resources when done to avoid unnecessary costs!