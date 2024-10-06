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
            "${local.terraform_cloud_hostname}:sub" : "organization:${terraform.cloud.organization}:project:${terraform.cloud.workspaces.project}:workspace:${terraform.cloud.workspaces.name}:run_phase:*"
          }
        }
      }
    ]
  })
}

# Creates a policy that will be used to define the permissions that
# the previously created role has within AWS.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "terraform_cloud_iam_policy" {
  name        = "TerraformCloudIamPolicy"
  description = "Terraform Choud run policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Creates an attachment to associate the above policy with the
# previously created role.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "terraform_cloud_iam_policy_attachment" {
  role       = aws_iam_role.terraform_cloud_role.name
  policy_arn = aws_iam_policy.terraform_cloud_iam_policy.arn
}
