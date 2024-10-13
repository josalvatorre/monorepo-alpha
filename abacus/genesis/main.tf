locals {
  the_abacus_app_email              = "the.abacus.app@gmail.com"
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
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "tfe" {}
provider "tls" {}
provider "aws" {
  region = "us-west-1"
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

resource "aws_organizations_account" "abacus_org" {
  name      = "abacus-org"
  email     = local.the_abacus_app_email
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

import {
  to = tfe_organization.terraform_cloud_organization
  id = "abacus_org"
}

resource "tfe_organization" "terraform_cloud_organization" {
  name  = "abacus_org"
  email = local.the_abacus_app_email
}

import {
  to = tfe_project.terraform_cloud_project
  id = "prj-ZCQTonyQt6mn3qQr"
}

resource "tfe_project" "terraform_cloud_project" {
  name         = "default_project"
  organization = tfe_organization.terraform_cloud_organization.name
}

import {
  to = tfe_workspace.terraform_cloud_genesis_workspace
  id = "ws-h7P1aXBjgAJQyuBg"
}

resource "tfe_workspace" "terraform_cloud_genesis_workspace" {
  name         = "genesis"
  organization = tfe_organization.terraform_cloud_organization.name
  project_id   = tfe_project.terraform_cloud_project.id
}
