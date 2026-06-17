
data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
  project = coalesce(var.project_id, data.google_project.project.project_id)
  depends_on = [
    google_project_service.api_setup
  ]
}

resource "google_compute_instance" "vm" {
  project                   = coalesce(var.project_id, data.google_project.project.project_id)
  name                      = var.instance_name
  machine_type              = var.machine_type
  zone                      = var.zone
  resource_policies         = []
  allow_stopping_for_update = false

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }

  network_interface {
    network = var.network
    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }

  tags = ["houston"]

  # Render the docker-run startup script instead of the deprecated
  # gce-container-declaration agent metadata.
  metadata_startup_script = templatefile("${path.module}/startup-script.sh.tftpl", {
    houston_password = random_password.admin_password.result
    houston_version  = var.houston_version
    tls_host         = var.tls_host
  })

  metadata = {
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  service_account {
    email  = coalesce(var.service_account_email, data.google_compute_default_service_account.default.email)
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.api_setup
  ]
}


// terraform import module.houston.google_compute_firewall.allow-houston-rule projects/tc-data-lake-dev-c94c/global/firewalls/default-allow-houston
resource "google_compute_firewall" "allow-tcp-80" {
  project     = coalesce(var.project_id, data.google_project.project.project_id)
  name        = "houston-allow-http"
  network     = var.network
  description = "Allow connections to the GCE Houston service on port 80 for Houston API calls"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000"]
  }

  # source_tags = []
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["houston"]
}

resource "google_compute_address" "public_ip" {
  name         = "houston-public-ip"
  description  = "The static Public IP for the Houston server"
  address_type = "EXTERNAL"
  region       = replace(var.zone, "/-.$/", "") // remove last character from zone to get region
}
