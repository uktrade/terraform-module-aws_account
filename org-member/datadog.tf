resource "aws_cloudwatch_event_connection" "eb-conn-datadog" {
  name               = "datadog-${var.member.name}-connection"
  description        = "Datadog visibility of AWS builds"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "DD-API-KEY"
      value = var.datadog-api-key
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "eb-apid-datadog" {
  name                             = "datadog-${var.member.name}-api-destination"
  description                      = "Datadog visibility of AWS builds"
  invocation_endpoint              = "https://webhook-intake.datadoghq.eu/api/v2/webhook"
  http_method                      = "POST"
  invocation_rate_limit_per_second = 20
  connection_arn                   = aws_cloudwatch_event_connection.eb-conn-datadog.arn
}

resource "aws_cloudwatch_event_rule" "ebr-datadog" {
  name        = "datadog-${var.member.name}-rule"
  description = "Datadog visibility of AWS builds"

  event_pattern = jsonencode({
    source = ["aws.codepipeline"]
    detail-type = [
      "CodePipeline Pipeline Execution State Change", "CodePipeline Action Execution State Change", "CodePipeline Stage Execution State Change"
    ]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.ebr-datadog.name
  arn       = aws_cloudwatch_event_api_destination.eb-apid-datadog.arn

  http_target {
    header_parameters = {
      "DD-CI-PROVIDER-AWSCODEPIPELINE": true
    }
  }
}

# Datadog API key, which gets stored in AWS Secrets Manager automatically
# EventBridge Connection, which will need the API key and API destination
# EventBridge Rule created for DataDog, which uses above API destination

 