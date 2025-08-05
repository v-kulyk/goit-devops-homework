variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "prometheus"
}

variable "chart_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = "56.21.0"
}

variable "namespace" {
  description = "Kubernetes namespace for Prometheus stack"
  type        = string
  default     = "monitoring"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "grafana_service_type" {
  description = "Service type for Grafana"
  type        = string
  default     = "LoadBalancer"
}

variable "prometheus_service_type" {
  description = "Service type for Prometheus"
  type        = string
  default     = "ClusterIP"
}

variable "alertmanager_service_type" {
  description = "Service type for Alertmanager"
  type        = string
  default     = "ClusterIP"
}

variable "cluster_dependency" {
  description = "Dependency on EKS cluster creation"
  type        = any
  default     = null
}