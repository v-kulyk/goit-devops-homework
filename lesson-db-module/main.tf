terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Backend and DynamoDB module
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.bucket_name
  table_name  = var.dynamodb_table_name
  tags        = var.common_tags
}

# VPC module
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name

  tags = var.common_tags
}

# ECR module
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_name
  scan_on_push = var.ecr_scan_on_push

  tags = var.common_tags
}

# EKS module
module "eks" {
  source           = "./modules/eks"
  cluster_name     = "goit-homework-eks-cluster"
  cluster_version  = "1.28"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  node_group_name  = "goit-homework-node-group"
  instance_types   = ["t2.micro"]
  desired_capacity = 1
  max_capacity     = 2
  min_capacity     = 1
}


module "jenkins" {
  source            = "./modules/jenkins"
  kubeconfig        = data.aws_eks_cluster.eks.endpoint
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  github_username   = var.github_username
  github_token      = var.github_token

  depends_on = [module.eks]

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}

module "argo_cd" {
  source          = "./modules/argo_cd"
  namespace       = "argocd"
  chart_version   = "5.46.4"
  github_username = var.github_username
  github_token    = var.github_token

  depends_on = [module.eks]
}


module "rds" {
  source = "./modules/rds"

  name                  = "djangoapp-db"
  use_aurora            = false
  aurora_instance_count = 2

  # --- Aurora-only ---
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"

  # --- RDS-only ---
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Common
  instance_class          = "db.t3.medium"
  allocated_storage       = 20
  db_name                 = var.postgres_db
  username                = var.postgres_user
  password                = var.postgres_password
  subnet_private_ids      = module.vpc.private_subnet_ids
  subnet_public_ids       = module.vpc.public_subnet_ids
  publicly_accessible     = true
  vpc_id                  = module.vpc.vpc_id
  multi_az                = false
  backup_retention_period = 7
  parameters = {
    max_connections            = "200"
    log_min_duration_statement = "500"
  }

  tags = {
    Environment = "dev"
    Project     = "djangoapp-db"
  }
}
