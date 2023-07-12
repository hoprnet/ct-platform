resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "oauth-grafana"
    namespace = "monitoring"
  }

  data = {
    "GF_AUTH_GOOGLE_CLIENT_ID"     = var.google_auth_grafana_client_id
    "GF_AUTH_GOOGLE_CLIENT_SECRET" = var.google_auth_grafana_client_secret
  }
}