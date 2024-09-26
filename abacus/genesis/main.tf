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
