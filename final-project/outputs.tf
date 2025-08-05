output "s3_bucket_name" {
  description = "S3 bucket with Terraform state"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table with Terraform state lock"
  value       = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.node_role_arn
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  value = module.eks.oidc_provider_url
}

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}


output "rds_endpoint" {
  description = "PostgreSQL endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_database" {
  description = "PostgreSQL database name"
  value       = var.postgres_db
}

output "rds_username" {
  description = "PostgreSQL username"
  value       = var.postgres_user
  sensitive   = true
}

# Monitoring outputs
output "prometheus_endpoint" {
  description = "Prometheus server endpoint"
  value       = module.prometheus.prometheus_endpoint
}

output "grafana_endpoint" {
  description = "Grafana server endpoint" 
  value       = module.grafana.grafana_endpoint
}
