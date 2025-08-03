variable "kubeconfig" {
  description = "Шлях до файлу kubeconfig"
  type        = string
}

variable "cluster_name" {
  description = "Назва кластера Kubernetes"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN OIDC провайдера для IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL OIDC провайдера для IRSA"
  type        = string
}

variable "github_username" {
  description = "Ім'я користувача GitHub"
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
