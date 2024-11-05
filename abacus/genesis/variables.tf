# At time of writing, there's no easy way to create an auto-rotating Terraform Enterprise API token.
# We'll have to constantly mint new ones.
variable "tfe_token" {
  type        = string
  sensitive   = true
  description = <<-EOT
  Terraform Enterprise API token. If it becomes expired, you'll need to create a new one.
  https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#team-api-tokens"
  EOT

  validation {
    condition     = length(var.tfe_token) > 0
    error_message = "TFE_TOKEN must be set. Please provide a valid Terraform Enterprise API token."
  }
}
