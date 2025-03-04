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

resource "aws_cloudwatch_event_target" "ebt-datadog" {
  rule      = aws_cloudwatch_event_rule.ebr-datadog.name
  arn       = aws_cloudwatch_event_api_destination.eb-apid-datadog.arn

  role_arn            = aws_iam_role.api_dest_role.arn

  http_target {
    header_parameters = {
      "DD-CI-PROVIDER-AWSCODEPIPELINE": true
    }
  }
}

# Datadog API key, which gets stored in AWS Secrets Manager automatically
# EventBridge Connection, which will need the API key and API destination
# EventBridge Rule created for DataDog, which uses above API destination

 
 # trust relationship document for role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# iam permission to allow API invocation for API destinations
resource "aws_iam_policy" "invoke_api_policy" {

  name        = "invoke-api-policy"
  path        = "/"
  description = "Allows invocation of target http api"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "events:InvokeApiDestination"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_cloudwatch_event_api_destination.eb-apid-datadog.arn}"
        ]
      },
    ]
  })
}

resource "aws_iam_role" "api_dest_role" {
  name               = "ApiDestinationRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# attach the invoke api policy
resource "aws_iam_role_policy_attachment" "invoke_api" {
  role       = aws_iam_role.api_dest_role.id
  policy_arn = aws_iam_policy.invoke_api_policy.arn
}
