locals {
  terraform_cloud_aws_oidc_audience = "terraform-cloud.aws-workload-identity"
  terraform_cloud_hostname          = "app.terraform.io"
  # TODO replace these with terraform.cloud.* references when we re-add the cloud block below.
  terraform_cloud_organization = "abacus_org"
  terraform_cloud_project      = "default_project"
  terraform_cloud_workspace    = "genesis"
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
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.71.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.59.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "tfe" {}

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
