# Універсальні outputs (працюють для обох типів)
output "endpoint" {
  description = "Database endpoint для підключення"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].endpoint
}

output "port" {
  description = "Database port"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

output "database_name" {
  description = "Назва бази даних"
  value       = var.db_name
}

output "username" {
  description = "Database username"
  value       = var.username
  sensitive   = true
}

# RDS-специфічні outputs
output "rds_instance_id" {
  description = "ID RDS інстансу (тільки для RDS)"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].id
}

output "rds_instance_arn" {
  description = "ARN RDS інстансу (тільки для RDS)"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].arn
}

# Aurora-специфічні outputs
output "aurora_cluster_id" {
  description = "ID Aurora кластера (тільки для Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].id : null
}

output "aurora_cluster_arn" {
  description = "ARN Aurora кластера (тільки для Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].arn : null
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint Aurora кластера (тільки для Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

# Спільні outputs
output "db_subnet_group_name" {
  description = "Назва DB subnet group"
  value       = aws_db_subnet_group.default.name
}

output "security_group_id" {
  description = "ID security group для бази даних"
  value       = aws_security_group.rds.id
}

output "parameter_group_name" {
  description = "Назва parameter group"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.aurora[0].name : aws_db_parameter_group.standard[0].name
}