
data "google_project" "project" {
}

data "google_compute_default_service_account" "default" {
  project = coalesce(var.project_id, data.google_project.project.project_id)
  depends_on = [
    google_project_service.api_setup
  ]
}

resource "google_compute_instance" "vm" {
  project      = coalesce(var.project_id, data.google_project.project.project_id)
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  resource_policies = []
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = module.gce-container-houston.source_image
    }
  }

  network_interface {
    network = var.network
    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }

  tags = ["houston"]

  metadata = {
    gce-container-declaration = module.gce-container-houston.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  labels = {
    container-vm = module.gce-container-houston.vm_container_label
  }

  service_account {
    email  = coalesce(var.service_account_email, data.google_compute_default_service_account.default.email)
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.api_setup
  ]
}


// https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest
// note: we don't need to say which ports to open
// note: this won't fail if container fails to start
module "gce-container-houston" {
  source    = "terraform-google-modules/container-vm/google"
  version   = "~> 3.0"
  container = {
    image        = "datasparq/houston-redis:${var.houston_version}"
    args         = ["api"]
    volumeMounts = [
      {
        mountPath = "/var/run/docker.sock"
        name      = "docker_sock"
      },
      {
        mountPath = "/data"
        name      = "data"
      }
    ]
    env = [
      {
        name = "HOUSTON_PASSWORD"
        value = random_password.admin_password.result
      },
      {
        name = "HOUSTON_PORT"
        value = 80
      },
      {
        name = "TLS_HOST"
        value = var.tls_host
      }
    ]
  }

  # Declare the Volumes which will be used for mounting.
  volumes = [
    {
      name     = "docker_sock"
      hostPath = {
        path = "/var/run/docker.sock"
      }
    },
    {
      name = "data"
      hostPath = {
        path = "/home/houston"
      }
    }
  ]

  restart_policy = "Always"
}


// terraform import module.houston.google_compute_firewall.allow-houston-rule projects/tc-data-lake-dev-c94c/global/firewalls/default-allow-houston
resource "google_compute_firewall" "allow-tcp-80" {
  project     = coalesce(var.project_id, data.google_project.project.project_id)
  name        = "houston-allow-http"
  network     = var.network
  description = "Allow connections to the GCE Houston service on port 80 for Houston API calls"

  allow {
    protocol  = "tcp"
    ports     = ["80", "443", "8000"]
  }

  source_tags = []
  target_tags = ["houston"]
}

resource "google_compute_address" "public_ip" {
  name = "houston-public-ip"
  description = "The static Public IP for the Houston server"
  address_type = "EXTERNAL"
  region = replace(var.zone, "/-.$/", "")  // remove last character from zone to get region
}
