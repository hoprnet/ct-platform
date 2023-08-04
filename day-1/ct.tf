#See main.tf for service account roles for ct
resource "google_service_account" "ct" {
  account_id   = "${var.name}-ct"
  display_name = "${var.name}-ct"
}

resource "google_service_account_iam_binding" "staging" {
  members = [
    "serviceAccount:${var.google_project}.svc.id.goog[staging/staging-economichandler]"
  ]
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.ct.name
}

resource "google_service_account_iam_binding" "production" {
  members = [
    "serviceAccount:${var.google_project}.svc.id.goog[production/production-economichandler]"
  ]
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.ct.name
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