/* 
This module sets up Terraform Cloud. It leverages the iam auth set up in aws-iam-auth-for-terraform-cloud.tf
to gain access to AWS.

Adapted from
https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/tree/5308cd970c0832f2180d7eb1e645dea33c4e344c/aws
*/

# Data source used to grab the project under which a workspace will be created.
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/project
data "tfe_project" "terraform_cloud_project" {
  name         = local.terraform_cloud_project_name
  organization = local.terraform_cloud_organization_name
}

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace
resource "tfe_workspace" "terraform_cloud_genesis_workspace" {
  name         = local.terraform_cloud_workspace_name
  organization = local.terraform_cloud_organization_name
  project_id   = data.tfe_project.terraform_cloud_project.id
}

# The following variables must be set to allow runs
# to authenticate to AWS.
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "terraform_cloud_enable_aws_provider_auth" {
  description = "Enable the Workload Identity integration for AWS."
  workspace_id = tfe_workspace.terraform_cloud_genesis_workspace.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

}

resource "tfe_variable" "tfc_aws_role_arn" {
  description = "The AWS role arn runs will use to authenticate."
  workspace_id = tfe_workspace.terraform_cloud_genesis_workspace.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.tfc_role.arn
  category = "env"
}
