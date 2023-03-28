
output "houston_base_url" {
  value = google_secret_manager_secret_version.base_url.secret_data
  sensitive = true
}

output "houston_password" {
  value = google_secret_manager_secret_version.admin_password.secret_data
  sensitive = true
}
