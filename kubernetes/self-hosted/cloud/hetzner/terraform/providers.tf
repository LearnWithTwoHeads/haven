# Tell Terraform to include the hcloud provider
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      # Here we use version 1.52.0, this may change in the future
      version = "1.52.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
