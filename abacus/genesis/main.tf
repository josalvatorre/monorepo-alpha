locals {
  terraform_cloud_aws_oidc_audience = "terraform-cloud.aws-workload-identity"
  terraform_cloud_hostname          = "app.terraform.io"
  terraform_cloud_organization      = "abacus_org"
  terraform_cloud_workspace         = "genesis"
  the_abacus_app_email              = "the.abacus.app@gmail.com"
}

terraform {
  # At time of writing, we simply use the latest version of Terraform available on HCP Terraform.
  required_version = ">= 1.9.8"
  # https://developer.hashicorp.com/terraform/language/terraform#terraform-cloud
  cloud {
    organization = "abacus_org"
    workspaces {
      name    = "genesis"
      # We wanted to use the default project, but Terraform Cloud failed to recognize it during deployments.
      # It looks like a bug in Terraform Cloud.
      project = "genesis_default_project"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.59.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "tfe" {
  hostname = local.terraform_cloud_hostname
}

provider "tls" {}

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

resource "aws_organizations_account" "abacus_org" {
  name  = "abacus-org"
  email = local.the_abacus_app_email
}

import {
  to = aws_organizations_account.abacus_images
  id = "992382556889"
}

resource "aws_organizations_account" "abacus_images" {
  name  = "abacus-images"
  email = "the.abacus.app+images@gmail.com"
}
