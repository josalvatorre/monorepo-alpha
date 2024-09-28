locals {
  terraform_cloud_aws_oidc_audience = "terraform-cloud.aws-workload-identity"
  terraform_cloud_hostname          = "app.terraform.io"
  terraform_cloud_organization_name = "abacus_org"
  terraform_cloud_project_name      = "default_project"
  terraform_cloud_workspace_name    = "genesis"
}

terraform {
  # At time of writing, we simply use the latest version of Terraform available on HCP Terraform.
  required_version = ">= 1.9.6"
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.68.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "tfe" {
  hostname = local.terraform_cloud_hostname
}

import {
  to = aws_organizations_organization.org
  id = "o-5hzhyf326b"
}

resource "aws_organizations_organization" "org" {
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html
  feature_set = "ALL"
  aws_service_access_principals = [
    "sso.amazonaws.com",
  ]
}

import {
  to = aws_organizations_account.abacus_org
  id = "339712758060"
}

# This is the root account for the org.
resource "aws_organizations_account" "abacus_org" {
  name      = "abacus-org"
  email     = "the.abacus.app@gmail.com"
  role_name = "OrganizationAccountAccessRole"
}

import {
  to = aws_organizations_account.abacus_images
  id = "992382556889"
}

resource "aws_organizations_account" "abacus_images" {
  name      = "abacus-images"
  email     = "the.abacus.app+images@gmail.com"
  role_name = "OrganizationAccountAccessRole"
}
