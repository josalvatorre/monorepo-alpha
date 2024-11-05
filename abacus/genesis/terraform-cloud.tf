/* 
This module sets up Terraform Cloud. It leverages the iam auth set up in aws-iam-auth-for-terraform-cloud.tf
to gain access to AWS.

Adapted from
https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/tree/5308cd970c0832f2180d7eb1e645dea33c4e344c/aws
*/

moved {
  from = tfe_variable.tfc_aws_role_arn
  to   = tfe_variable.terraform_cloud_aws_role_arn
}

moved {
  from = tfe_organization.terraform_cloud_organization
  to   = tfe_organization.abacus_org
}

moved {
  from = tfe_project.terraform_cloud_project
  to   = tfe_project.genesis_default_project
}

moved {
  from = tfe_workspace.terraform_cloud_genesis_workspace
  to   = tfe_workspace.genesis_workspace
}

import {
  to = tfe_organization.abacus_org
  id = local.terraform_cloud_organization
}

import {
  to = tfe_workspace.genesis_workspace
  id = "ws-h7P1aXBjgAJQyuBg"
}

import {
  to = tfe_project.genesis_default_project
  id = "prj-ZCQTonyQt6mn3qQr"
}

import {
  to = tfe_team.owners
  id = "${local.terraform_cloud_organization}/${local.terraform_team_id}"
}

import {
  to = tfe_variable.terraform_cloud_enable_aws_provider_auth
  id = "${local.terraform_cloud_organization}/${local.terraform_genesis_workspace_name}/var-fE3LmiR7MhAWQ9ax"
}

import {
  to = tfe_variable.terraform_cloud_aws_role_arn
  id = "${local.terraform_cloud_organization}/${local.terraform_genesis_workspace_name}/var-huZCuu3ySPNNdakZ"
}

import {
  to = tfe_variable.terraform_cloud_tfc_aws_audience
  id = "${local.terraform_cloud_organization}/${local.terraform_genesis_workspace_name}/var-DQ1T12MqnMUBtDEa"
}

resource "tfe_organization" "abacus_org" {
  name  = local.terraform_cloud_organization
  email = local.the_abacus_app_email
}

resource "tfe_project" "genesis_default_project" {
  name         = "default_project"
  organization = tfe_organization.abacus_org.name
}

resource "tfe_team" "owners" {
  name         = "owners"
  organization = tfe_organization.abacus_org.name
}

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace
resource "tfe_workspace" "genesis_workspace" {
  name                  = local.terraform_genesis_workspace_name
  organization          = tfe_organization.abacus_org.name
  project_id            = tfe_project.genesis_default_project.id
  working_directory     = "abacus/genesis"
  file_triggers_enabled = false
  description           = "See description at https://github.com/josalvatorre/monorepo-alpha/tree/f41243576d015278683fa2d41b9f9a086e9a09fc/abacus/genesis"
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
  workspace_id = tfe_workspace.genesis_workspace.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

}

# Required for authentication to AWS
# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration#required-environment-variables
resource "tfe_variable" "terraform_cloud_aws_role_arn" {
  description  = "The AWS role arn runs will use to authenticate."
  workspace_id = tfe_workspace.genesis_workspace.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.terraform_cloud_role.arn
  category = "env"
}

resource "tfe_variable" "terraform_cloud_tfc_aws_audience" {
  description  = "The value to use as the audience claim in run identity tokens"
  workspace_id = tfe_workspace.genesis_workspace.id

  key      = "TFC_AWS_WORKLOAD_IDENTITY_AUDIENCE"
  value    = local.terraform_cloud_aws_oidc_audience
  category = "env"
}
