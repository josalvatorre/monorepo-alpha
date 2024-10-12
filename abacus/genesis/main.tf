locals {
  terraform_cloud_aws_oidc_audience = "terraform-cloud.aws-workload-identity"
  terraform_cloud_hostname          = "app.terraform.io"
  # TODO replace these with terraform.cloud.* references when we re-add the cloud block below.
  terraform_cloud_organization      = "abacus_org"
  terraform_cloud_project           = "default_project"
  terraform_cloud_workspace         = "genesis"
}

terraform {
  # At time of writing, we simply use the latest version of Terraform available on HCP Terraform.
  required_version = ">= 1.9.7"
  # TODO Add this back in when AWS auth is set up.
  # https://developer.hashicorp.com/terraform/language/terraform#terraform-cloud
  # cloud {
  #   organization = "abacus_org"
  #   workspaces {
  #     name    = "genesis"
  #     project = "default_project"
  #   }
  # }
}
