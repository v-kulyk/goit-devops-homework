variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-locks"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "lesson-5-vpc"
}

variable "ecr_name" {
  description = "Name for ECR repository"
  type        = string
  default     = "lesson-5-ecr"
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "lesson-8-9"
    Project     = "terraform-learning"
  }
}

variable "github_username" {
  description = "GitHub username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  default     = ""
  sensitive   = true
}


variable "postgres_host" {
  description = "PostgreSQL host"
  type        = string
  default     = "localhost"
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = string
  default     = "5432"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "myapp"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

# Додаткові змінні для різних типів баз даних
variable "mysql_password" {
  description = "MySQL password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "prod_db_password" {
  description = "Production database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aurora_mysql_password" {
  description = "Aurora MySQL password"
  type        = string
  default     = ""
  sensitive   = true
}

# ===================================
# RDS MODULE CONFIGURATION VARIABLES
# ===================================

variable "use_aurora" {
  description = "Use Aurora cluster instead of regular RDS"
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "db_engine" {
  description = "Database engine (postgres, mysql)"
  type        = string
  default     = "postgres"
  
  validation {
    condition     = contains(["postgres", "mysql"], var.db_engine)
    error_message = "Database engine must be either 'postgres' or 'mysql'."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "17.2"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

# Aurora specific variables
variable "aurora_instance_count" {
  description = "Number of instances in Aurora cluster"
  type        = number
  default     = 2
  
  validation {
    condition     = var.aurora_instance_count >= 1 && var.aurora_instance_count <= 15
    error_message = "Aurora instance count must be between 1 and 15."
  }
}

variable "aurora_engine" {
  description = "Aurora engine (aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
  
  validation {
    condition     = contains(["aurora-postgresql", "aurora-mysql"], var.aurora_engine)
    error_message = "Aurora engine must be either 'aurora-postgresql' or 'aurora-mysql'."
  }
}

variable "aurora_engine_version" {
  description = "Aurora engine version"
  type        = string
  default     = "15.3"
}

# ===================================
# ENVIRONMENT SPECIFIC VARIABLES
# ===================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "myapp"
}

# ===================================
# DATABASE PARAMETERS
# ===================================

variable "postgres_parameters" {
  description = "PostgreSQL specific parameters"
  type        = map(string)
  default = {
    max_connections            = "200"
    log_min_duration_statement = "500"
    work_mem                   = "4096"
    shared_preload_libraries   = "pg_stat_statements"
  }
}

variable "mysql_parameters" {
  description = "MySQL specific parameters"
  type        = map(string)
  default = {
    max_connections         = "1000"
    innodb_buffer_pool_size = "268435456"
    slow_query_log          = "1"
    long_query_time         = "2"
  }
}

variable "aurora_postgres_parameters" {
  description = "Aurora PostgreSQL specific parameters"
  type        = map(string)
  default = {
    max_connections = "200"
    work_mem        = "4096"
    log_statement   = "mod"
  }
}

variable "aurora_mysql_parameters" {
  description = "Aurora MySQL specific parameters"
  type        = map(string)
  default = {
    max_connections         = "2000"
    innodb_buffer_pool_size = "1073741824"
    binlog_format           = "ROW"
  }
}
