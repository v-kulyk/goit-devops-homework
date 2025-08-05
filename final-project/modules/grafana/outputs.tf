output "grafana_namespace" {
  description = "Namespace where Grafana is deployed"
  value       = helm_release.grafana.namespace
}

output "grafana_release_name" {
  description = "Name of the Grafana Helm release"
  value       = helm_release.grafana.name
}

output "grafana_chart_version" {
  description = "Version of the deployed Grafana chart"
  value       = helm_release.grafana.version
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = helm_release.grafana.name
}

output "grafana_url" {
  description = "URL to access Grafana (when using LoadBalancer)"
  value       = var.service_type == "LoadBalancer" ? "http://<EXTERNAL-IP>" : "http://${helm_release.grafana.name}.${helm_release.grafana.namespace}.svc.cluster.local"
}

output "admin_username" {
  description = "Admin username for Grafana"
  value       = "admin"
}

output "admin_password" {
  description = "Admin password for Grafana"
  value       = var.admin_password
  sensitive   = true
}

output "grafana_endpoint" {
  description = "Grafana server endpoint"
  value       = var.service_type == "LoadBalancer" ? "http://<EXTERNAL-IP>:80" : "http://${helm_release.grafana.name}.${helm_release.grafana.namespace}.svc.cluster.local:80"
}