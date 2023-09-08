#See main.tf for service account roles for ct
resource "google_service_account" "ct_staging" {
  account_id   = "${var.name}-ct-staging"
  display_name = "${var.name}-ct-staging"
}

resource "google_service_account" "ct_production" {
  account_id   = "${var.name}-ct-production"
  display_name = "${var.name}-ct-production"
}

resource "google_service_account_iam_binding" "staging" {
  members = [
    "serviceAccount:${var.google_project}.svc.id.goog[staging/staging-economic-handler]"
  ]
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.ct_staging.name
}

resource "google_service_account_iam_binding" "production" {
  members = [
    "serviceAccount:${var.google_project}.svc.id.goog[production/production-economic-handler]"
  ]
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.ct_production.name
}

resource "google_storage_bucket" "ct" {
  location                    = var.google_region
  force_destroy               = false
  name                        = "${var.name}-ct"
  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true

  autoclass {
    enabled = true
  }
}