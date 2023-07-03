
variable "zone" {
  type = string
  description = "Google compute zone for the Virtual Machine, e.g. 'europe-west2-a'."
}

variable "project_id" {
  type = string
  default = null
  description = "GCP project ID in which the Compute Engine Virtual Machine will be created. If none is provided then the provider project will be used."
}

variable "network" {
  type = string
  default = "default"
  description = "Name of the Google Cloud Virtual Private Cloud Network to use."
}

variable "service_account_email" {
  type = string
  default = null
  description = "Google service account to be used by the Virtual Machine. If none is provided then the Compute Engine default service account for the provider project will be used."
}

variable "machine_type" {
  type = string
  default = "e2-small"  # 1 shared core, 2 GB Memory
  description = "Machine type for the Virtual Machine. Defaults to a small machine to minimise costs."
}

variable "instance_name" {
  type = string
  default = "houston"
  description = "Name for the Virtual Machine."
}

variable "tls_host" {
  type = string
  default = ""
  description = "Host domain name to be used for the server, which is passed to the Houston API via the 'TLS_HOST' environment variable. A TLS/SSL certificate will be generated via the ACME protocol and Let's Encrypt (https://letsencrypt.org/). If an empty host is provided, the server will only use HTTP. See the documentation for more information: https://github.com/datasparq-ai/houston/blob/main/docs/tls.md"
}

variable "houston_version" {
  type = string
  default = "latest"
  description = "Houston container tag to use."
}

variable "base_url_secret_id" {
  type = string
  default = "houston-base-url"
  description = "Name to use for the secret which stores the Houston API base URL."
}

variable "admin_password_secret_id" {
  type = string
  default = "houston-admin-password"
  description = "Name to use for the secret which stores the Houston API admin password."
}
