resource "helm_release" "prometheus" {
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.service.type"
    value = var.grafana_service_type
  }

  set {
    name  = "prometheus.service.type"
    value = var.prometheus_service_type
  }

  set {
    name  = "alertmanager.service.type"
    value = var.alertmanager_service_type
  }

  depends_on = [var.cluster_dependency]
}