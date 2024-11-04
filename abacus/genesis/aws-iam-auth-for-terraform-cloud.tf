/* 
This module sets up auth for Terraform Cloud to manage our AWS organization using dynamic credentials.
This is inherently safer than using long-lived credentials.

Adapted from
https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/tree/5308cd970c0832f2180d7eb1e645dea33c4e344c/aws
*/

# Data source used to grab the TLS certificate for Terraform Cloud.
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "terraform_cloud_certificate" {
  url = "https://${local.terraform_cloud_hostname}"
}

# Creates an OIDC provider which is restricted to
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "terraform_iam_openid_provider" {
  url             = data.tls_certificate.terraform_cloud_certificate.url
  client_id_list  = [local.terraform_cloud_aws_oidc_audience]
  thumbprint_list = [data.tls_certificate.terraform_cloud_certificate.certificates[0].sha1_fingerprint]
}

# Creates a role which can only be used by the specified Terraform cloud workspace.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "terraform_cloud_role" {
  name = "TerraformCloudRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${aws_iam_openid_connect_provider.terraform_iam_openid_provider.arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.terraform_cloud_hostname}:aud" : one(aws_iam_openid_connect_provider.terraform_iam_openid_provider.client_id_list)
          },
          "StringLike" : {
            "${local.terraform_cloud_hostname}:sub" : "organization:${tfe_organization.abacus_org.name}:project:${tfe_project.genesis_default_project.name}:workspace:${tfe_workspace.terraform_cloud_genesis_workspace.name}:run_phase:*"
          }
        }
      }
    ]
  })
}

# "Provides full access to AWS services and resources, but does not allow management of Users and groups."
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/PowerUserAccess.html
resource "aws_iam_role_policy_attachment" "terraform_cloud_power_user_policy_attachment" {
  role       = aws_iam_role.terraform_cloud_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# "Provides full access to IAM via the AWS Management Console."
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/IAMFullAccess.html
resource "aws_iam_role_policy_attachment" "terraform_cloud_iam_policy_attachment" {
  role       = aws_iam_role.terraform_cloud_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSOrganizationsFullAccess.html
resource "aws_iam_role_policy_attachment" "terraform_cloud_organizations_policy_attachment" {
  role       = aws_iam_role.terraform_cloud_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_cloud_deny_s3_deletions_attachment" {
  role       = aws_iam_role.terraform_cloud_role.name
  policy_arn = aws_iam_policy.deny_s3_deletions.arn
}

resource "aws_iam_policy" "deny_s3_deletions" {
  name        = "DenyS3Deletions"
  description = "Denies deletion of S3 buckets and objects"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = "*"
      }
    ]
  })
}
