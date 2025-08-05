output "prometheus_namespace" {
  description = "Namespace where Prometheus stack is deployed"
  value       = helm_release.prometheus.namespace
}

output "prometheus_release_name" {
  description = "Name of the Prometheus Helm release"
  value       = helm_release.prometheus.name
}

output "prometheus_chart_version" {
  description = "Version of the deployed Prometheus chart"
  value       = helm_release.prometheus.version
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = "${helm_release.prometheus.name}-grafana"
}

output "prometheus_service_name" {
  description = "Name of the Prometheus service"
  value       = "${helm_release.prometheus.name}-kube-prometheus-prometheus"
}

output "alertmanager_service_name" {
  description = "Name of the Alertmanager service"
  value       = "${helm_release.prometheus.name}-kube-prometheus-alertmanager"
}

output "prometheus_endpoint" {
  description = "Prometheus server endpoint"
  value       = "http://${helm_release.prometheus.name}-kube-prometheus-prometheus.${helm_release.prometheus.namespace}.svc.cluster.local:9090"
}