
# generate a password to use as the admin password
resource "random_password" "admin_password" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "admin_password" {
  project = coalesce(var.project_id, data.google_project.project.project_id)
  secret_id = var.admin_password_secret_id
  replication {
    auto = true
  }
}
resource "google_secret_manager_secret_version" "admin_password" {
  secret =  google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin_password.result
}

locals {
  base_url = var.tls_host == "" ? "http://${google_compute_address.public_ip.address}/api/v1" : "https://${var.tls_host}/api/v1"
}
resource "google_secret_manager_secret" "base_url" {
  project = coalesce(var.project_id, data.google_project.project.project_id)
  secret_id =  var.base_url_secret_id
  replication {
    auto = true
  }
  depends_on = [
    google_compute_instance.vm
  ]
}
resource "google_secret_manager_secret_version" "base_url" {
  secret =  google_secret_manager_secret.base_url.id
  secret_data = local.base_url
}

