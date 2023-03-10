
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

  metadata_startup_script = templatefile("${path.module}/startup.sh.tpl",
  {
    config_path = "/etc/docker/docker-compose.yaml"
    houston_password = random_password.admin_password.result
    houston_version = var.houston_version
    redis_version = var.redis_version
  })

  depends_on = [
    google_project_service.api_setup
  ]
}


// https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest
// this is the equivalent of signing into the VM and running:
//     docker run -v /etc/docker/docker-compose.yaml:/docker-compose.yaml -v "/var/run/docker.sock:/var/run/docker.sock" docker compose up
module "gce-container-houston" {
  source    = "terraform-google-modules/container-vm/google"
  version   = "~> 3.0"
  container = {
    image        = "docker:latest"
    command      = ["docker"]
    args         = ["compose", "up"]
    volumeMounts = [
      {
        mountPath = "/docker-compose.yaml"
        name      = "config"
        readOnly  = true
      },
      {
        mountPath = "/var/run/docker.sock"
        name      = "docker_sock"
      }
    ]
  }

  # Declare the Volumes which will be used for mounting.
  volumes = [
    {
      name = "config"
      hostPath = {
        path = "/etc/docker/docker-compose.yaml"
      }
    },
    {
      name = "docker_sock"
      hostPath = {
        path = "/var/run/docker.sock"
      }
    }
  ]

  restart_policy = "Always"
}


// terraform import module.houston.google_compute_firewall.allow-houston-rule projects/tc-data-lake-dev-c94c/global/firewalls/default-allow-houston
resource "google_compute_firewall" "allow-tcp-80" {
  project     = coalesce(var.project_id, data.google_project.project.project_id)
  name        = "default-allow-houston"
  network     = var.network
  description = "Allow houston connections to the gce houston service on port 80"

  allow {
    protocol  = "tcp"
    ports     = ["80", "8000"]
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
