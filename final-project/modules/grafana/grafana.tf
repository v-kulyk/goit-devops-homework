resource "helm_release" "grafana" {
  name       = var.release_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]

  set_sensitive {
    name  = "adminPassword"
    value = var.admin_password
  }

  set {
    name  = "service.type"
    value = var.service_type
  }

  set {
    name  = "persistence.enabled"
    value = var.persistence_enabled
  }

  set {
    name  = "persistence.size"
    value = var.persistence_size
  }

  set {
    name  = "persistence.storageClassName"
    value = var.storage_class_name
  }

  depends_on = [var.cluster_dependency]
}