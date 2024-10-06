terraform {
  # At time of writing, we simply use the latest version of Terraform available on HCP Terraform.
  required_version = ">= 1.9.7"
  # https://developer.hashicorp.com/terraform/language/terraform#terraform-cloud
  cloud {
    organization = "abacus_org"
    workspaces {
      name    = "genesis"
      project = "default_project"
    }
  }
}
