variable "google_project" {
  type        = string
  description = "The ID of the GCP project"
  sensitive   = true
}

variable "google_region" {
  type        = string
  description = "The default GCP region for resource placement"
  sensitive   = true
}

variable "name" {
  type        = string
  description = "The name used in naming resources"
}

variable "domain" {
  type        = string
  description = "The domain name for the DNS zone and other resources"
}

variable "argocd_repo_url" {
  type        = string
  description = "The URL for the ArgoCD repository"
}

variable "argocd_credentials_url" {
  type        = string
  description = "The URL for the ArgoCD credentials template"
}

variable "argocd_credentials_key" {
  type        = string
  description = "The base64 encoded SSH private key for the ArgoCD credentials template"
  sensitive   = true
}

variable "google_auth_grafana_client_id" {
  type        = string
  description = "The client ID of the GCP OAuth Grafana client"
  sensitive   = true
}

variable "google_auth_grafana_client_secret" {
  type        = string
  description = "The client secret of the GCP OAuth Grafana client"
  sensitive   = true
}

variable "google_auth_traefik_client_id" {
  type        = string
  description = "The client ID of the GCP OAuth Traefik client"
  sensitive   = true
}

variable "google_auth_traefik_client_secret" {
  type        = string
  description = "The client secret of the GCP OAuth Traefik client"
  sensitive   = true
}

variable "environment_names" {
  description = "List of environment names"
  type        = list(string)
  default     = ["production", "staging"]
}

variable "dbname" {
  type        = string
  description = "The database name"
  default     = "ctdapp"
}
