
resource "google_project_service" "api_setup" {
  for_each = toset([
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
  ])
  service = each.key
  project = var.project_id
  disable_on_destroy = false
}
