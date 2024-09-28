# Adapted from
# https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/5308cd970c0832f2180d7eb1e645dea33c4e344c/aws/aws.tf

# Data source used to grab the TLS certificate for Terraform Cloud.
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "terraform_cloud_certificate" {
  url = "https://${var.tfc_hostname}"
}

# Creates an OIDC provider which is restricted to
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "terraform_iam_openid_provider" {
  url             = data.tls_certificate.terraform_cloud_certificate.url
  client_id_list  = [var.tfc_aws_audience]
  thumbprint_list = [data.tls_certificate.terraform_cloud_certificate.certificates[0].sha1_fingerprint]
}

# Creates a role which can only be used by the specified Terraform cloud workspace.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "terraform_cloud_role" {
  name = "terraformCloudRole"
  # TODO There's surely a way to use JSON loader instead of a literal string.
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
            "${var.tfc_hostname}:aud" : one(aws_iam_openid_connect_provider.terraform_iam_openid_provider.client_id_list)
          },
          "StringLike" : {
            "${var.tfc_hostname}:sub" : "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.tfc_workspace_name}:run_phase:*"
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
  name        = "terraformCloudIamPolicy"
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
