
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
  default = "e2-micro"  # 1 shared core, 1 GB Memory
  description = "Machine type for the Virtual Machine. Defaults to a very small machine to minimise costs."
}

variable "instance_name" {
  type = string
  default = "houston"
  description = "Name for the Virtual Machine."
}

variable "houston_version" {
  type = string
  default = "latest"
  description = "Houston container tag to use."
}

variable "redis_version" {
  type = string
  default = "latest"
  description = "Redis container tag to use."
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
