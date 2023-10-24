
output "houston_base_url" {
  value = local.base_url
  sensitive = false
  description = "URL of the Houston API, which should be provided to any service running the Houston client via the 'HOUSTON_BASE_URL' environment variable."
}

output "houston_password" {
  value = google_secret_manager_secret_version.admin_password.secret_data
  sensitive = true
  description = "Admin password for the Houston API which has been randomly generated by this module. This password is required for functions such as creating or deleting API keys."
}

output "ip_address" {
  value = google_compute_address.public_ip.address
  sensitive = false
  description = "IP address of the Houston VM instance."
}
