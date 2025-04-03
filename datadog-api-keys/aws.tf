data "aws_caller_identity" "current" {
  provider = aws.member
}

locals {
  tags = {
    managed-by          = "DBT Platform - Terraform"
  }

  alias = var.account_alias
}

// Create some dummy/placeholder keys

resource "aws_ssm_parameter" "datadog_api_key_placeholder" {
  provider = aws.member

  name        = "DATADOG_API_KEY"
  description = "An API key for sending data to datadog for the ${local.alias} account only."
  type        = "SecureString"
  value       = "placeholder"

  tags = local.tags
}

resource "aws_ssm_parameter" "datadog_app_key" {
  provider = aws.member

  name        = "DATADOG_APP_KEY"
  description = "An APP key for sending data to datadog for the ${local.alias} account only."
  type        = "SecureString"
  value       = "placeholder"

  tags = local.tags
}
