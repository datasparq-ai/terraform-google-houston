

# Houston Container GCE Service Terraform Module

This module uses Google's [container-vm](https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest) 
Terraform module to create a Houston server in Google Compute Engine using the [Houston Docker image](https://hub.docker.com/repository/docker/datasparq/houston-redis/general).

The following Google Cloud IAM roles are required to create this module:
- roles/editor (Editor): for creating compute and networking resources
- roles/secretmanager.viewer (Secret Manager Viewer): for creating and reading secrets

Creates the following resources:
- google_compute_instance.vm: The Houston API server
- google_compute_address.public_ip: A static public IP address for the Houston service
- google_compute_firewall.allow-http-rule: Firewall rule that allows TCP protocol traffic to port 80 and 443 on this instance
- Admin password secret:
  - random_password.admin_password: Randomly generated password for Houston API admin
  - google_secret_manager_secret.admin_password: Secret in GCP secret manager for the admin password
  - google_secret_manager_secret_version.admin_password: Secret version for the admin password
- Base URL secret:
  - google_secret_manager_secret.base_url: Secret in GCP secret manager for the API base URL
  - google_secret_manager_secret_version.base_url: Secret version for the API base URL

### Usage

A simple Houston API server can be deployed with the following configuration:

```hcl-terraform
provider "google" {
  project = "<your Google Cloud project ID>"
}

module "houston" {
  source = "datasparq-ai/houston/google"
  zone   = "europe-west2-a"
}
```

If you have a domain name and can create the required DNS records, you can enable TLS/SSL/HTTPS by specifying the hostname you will be using to point to your server.
A TLS/SSL certificate will be generated via the ACME protocol and [Let's Encrypt](https://letsencrypt.org/). 
If an empty host is provided, the server will only use HTTP. See the documentation for more information and step-by-step instructions: [TLS/SSL/HTTPS](https://github.com/datasparq-ai/houston/blob/main/docs/tls.md)

```hcl-terraform
provider "google" {
  project = "<your Google Cloud project ID>"
}

module "houston" {
  source   = "datasparq-ai/houston/google"
  zone     = "europe-west2-a"
  tls_host = "houston.example.com"
}
```


### Performance 

This service, running on the default `e2-small` (2 GB Memory) instance, can easily handle 10 large concurrent missions.


### Deployment

This uses Google's [container-vm](https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest) 
terraform module to generate a container spec, which is then provided to a Google Compute Instance.

Note: `terraform apply` will want to stop and restart this instance every time a new version of the COS image 
(container-optimised OS) becomes available, which may result in temporary downtime.


### Connect via SSH

For convenience, use gcloud as this will transfer your SSH key to the instance for you.

    gcloud auth login
    gcloud config set project your-gcp-project
    gcloud compute ssh houston --zone=europe-west2-a

Alternatively, use an ssh client. After adding your SSH public key to the Houston VM instance, use:

    ssh -L 8000:<Instance IP Address>:8000 <username>@<Instance IP Address>

