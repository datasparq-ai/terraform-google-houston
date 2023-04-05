
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
    tls_host = var.tls_host
    houston_version = var.houston_version
    redis_version = var.redis_version
  })

  depends_on = [
    google_project_service.api_setup
  ]
}


// https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest
// this is the equivalent of signing into the VM and running:
//     docker run -v /etc/docker/docker-compose.yaml:/docker-compose.yaml -v "/var/run/docker.sock:/var/run/docker.sock" docker compose up --wait
module "gce-container-houston" {
  source    = "terraform-google-modules/container-vm/google"
  version   = "~> 3.0"
  container = {
    image        = "docker:latest"
    command      = ["docker"]
    args         = ["compose", "-p", "houston", "up", "--wait"]
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

# this forces terraform to wait until the API is ready before continuing
# this will only work if either curl or wget is installed
# wget is used because this is available in the official hashicorp/terraform Docker container
resource "null_resource" "wait-for-availability" {
  provisioner "local-exec" {
    command = <<-EOF
    #!/bin/sh
    MSG="{\"message\":\"all systems green\"}"
    healthcheck_1="wget -qO- ${local.base_url}"
    healthcheck_2="curl ${local.base_url} --silent"
    count=0
    while [[ "$($healthcheck_1)" != "$MSG" && "$($healthcheck_2)" != "$MSG" ]] ; do
      echo "Waiting for Houston API to become available. This can take around 3 minutes."
      if [[ $count -gt 300 ]] ; then
        echo -e "Reached the maximum wait time - exiting"
        exit 1
      else
        count=`expr $count + 1`
        sleep 5
      fi
    done
    EOF
  }
  triggers = {
    always_run = timestamp()
  }
  depends_on = [google_compute_instance.vm]
}
