resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
  wait_for_default_service_account = false
  timeouts {}
}

resource "kubernetes_secret" "traefik" {
  metadata {
    name      = "oauth-traefik"
    namespace = "traefik"
  }

  data = {
    "TRAEFIK_AUTH_GOOGLE_CLIENT_ID"     = var.google_auth_traefik_client_id
    "TRAEFIK_AUTH_GOOGLE_CLIENT_SECRET" = var.google_auth_traefik_client_secret
  }
}