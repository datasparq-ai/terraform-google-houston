

# Houston Container GCE Service Terraform Module

This module uses Google's [container-vm](https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest) terraform module.

Creates the following resources:
- google_compute_instance.vm: The Houston API server
- google_compute_address.public_ip: A static public IP address for the Houston service
- google_compute_firewall.allow-http-rule: Firewall rule that allows TCP protocol traffic to port 80 on this instance
- Admin password secret:
  - random_password.admin_password: Randomly generated password for Houston API admin
  - google_secret_manager_secret.admin_password: Secret in GCP secret manager for the admin password
  - google_secret_manager_secret_version.admin_password: Secret version for the admin password
- Base URL secret: 
  - google_secret_manager_secret.base_url: Secret in GCP secret manager for the API base URL
  - google_secret_manager_secret_version.base_url: Secret version for the API base URL

### Usage

```hcl-terraform
module "houston" {
  source = "datasparq-ai/terraform-google-houston"
  zone   = "europe-west2-a"
}
```

### Performance 

This service, running on a `e2-standard-2` (2 CPU, 8GiB Memory) instance, can easily handle 10 large concurrent missions.

### Deployment

This uses Google's [container-vm](https://registry.terraform.io/modules/terraform-google-modules/container-vm/google/latest) terraform module.

The server should not be need to be redeployed.  


### Connect via SSH

For convenience, use gcloud as this will transfer your SSH key to the instance for you.

    gcloud auth login
    gcloud config set project your-gcp-project
    gcloud compute ssh houston --zone=europe-west2-a

Alternatively, use an ssh client. After adding your SSH public key to the Houston VM instance, use:

    ssh -L 8000:<Instance IP Address>:8000 <username>@<Instance IP Address>


