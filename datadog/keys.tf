resource "datadog_application_key" "app_key" {
  name = "aws-account-${local.alias}"
}

resource "datadog_api_key" "api_key" {
  name = "aws-account-${local.alias}"
}

resource "aws_ssm_parameter" "datadog_api_key" {
  provider = aws.member

  name        = "DATADOG_API_KEY"
  description = "An API key for sending data to datadog for the ${local.alias} account only."
  type        = "SecureString"
  value       = resource.datadog_api_key.api_key.key

  tags = merge(local.tags, {
    "copilot-application"="__all__"
  })
}

resource "aws_ssm_parameter" "datadog_app_key" {
  provider = aws.member

  name        = "DATADOG_APP_KEY"
  description = "An APP key for sending data to datadog for the ${local.alias} account only."
  type        = "SecureString"
  value       = resource.datadog_application_key.app_key.key

  tags = merge(local.tags, {
    "copilot-application"="__all__"
  })
}
