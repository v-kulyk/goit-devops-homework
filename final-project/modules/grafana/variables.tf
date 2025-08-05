variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "grafana"
}

variable "chart_version" {
  description = "Version of the Grafana Helm chart"
  type        = string
  default     = "7.3.0"
}

variable "namespace" {
  description = "Kubernetes namespace for Grafana"
  type        = string
  default     = "monitoring"
}

variable "admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "service_type" {
  description = "Service type for Grafana"
  type        = string
  default     = "LoadBalancer"
}

variable "persistence_enabled" {
  description = "Enable persistence for Grafana"
  type        = bool
  default     = true
}

variable "persistence_size" {
  description = "Size of persistent volume for Grafana"
  type        = string
  default     = "2Gi"
}

variable "storage_class_name" {
  description = "Storage class name for persistent volume"
  type        = string
  default     = "gp2"
}

variable "prometheus_url" {
  description = "URL of Prometheus server for data source"
  type        = string
  default     = "http://prometheus-server:80"
}

variable "cluster_dependency" {
  description = "Dependency on EKS cluster creation"
  type        = any
  default     = null
}