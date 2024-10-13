/* 
This module sets up Terraform Cloud. It leverages the iam auth set up in aws-iam-auth-for-terraform-cloud.tf
to gain access to AWS.

Adapted from
https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/tree/5308cd970c0832f2180d7eb1e645dea33c4e344c/aws
*/

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

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace
resource "tfe_workspace" "terraform_cloud_genesis_workspace" {
  name              = local.terraform_cloud_workspace
  organization      = local.terraform_cloud_organization
  project_id        = tfe_project.terraform_cloud_project.id
  working_directory = "abacus/genesis"
  vcs_repo {
    branch                     = null
    github_app_installation_id = "ghain-1ByhkGkwQgB5bkex"
    identifier                 = "josalvatorre/monorepo-alpha"
  }
}

# Required for authentication to AWS
# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration#required-environment-variables
resource "tfe_variable" "terraform_cloud_enable_aws_provider_auth" {
  description  = "Enable the Workload Identity integration for AWS."
  workspace_id = tfe_workspace.terraform_cloud_genesis_workspace.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

}

# Required for authentication to AWS
# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration#required-environment-variables
resource "tfe_variable" "tfc_aws_role_arn" {
  description  = "The AWS role arn runs will use to authenticate."
  workspace_id = tfe_workspace.terraform_cloud_genesis_workspace.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.terraform_cloud_role.arn
  category = "env"
}
