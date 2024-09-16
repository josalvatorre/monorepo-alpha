provider "aws" {
  region = "us-west-1"
}

import {
  to = aws_organizations_organization.org
  id = "o-5hzhyf326b"
}

resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
    "sso.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
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

resource "aws_iam_group" "engineers" {
  name = "engineers"
}

resource "aws_iam_group_policy_attachment" "engineer_policies" {
  group      = aws_iam_group.engineers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
