# AWS Backup

## Lambda

# tflint-ignore: terraform_required_providers
data "archive_file" "backup_slack_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/backup-slack.py"
  output_path = "${path.module}/lambda/backup-slack.py.zip"
}

resource "aws_lambda_function" "aws_backup_to_slack" {
  provider                        = aws.master
  function_name                   = "aws-backup-to-slack"
  description                     = "An Amazon SNS trigger that sends AWS Backup Notifications to Slack."
  filename                        = data.archive_file.backup_slack_zip.output_path
  role                            = aws_iam_role.aws_backup_to_slack.arn
  handler                         = "backup-slack.lambda_handler"
  source_code_hash                = data.archive_file.backup_slack_zip.output_base64sha256
  runtime                         = "python3.9"
  reserved_concurrent_executions  = 100
  environment {
    variables = {
      kmsEncryptedHookUrl = var.org["backup_alert_slack_webhook"]
      slackChannelSuccess = var.org["backup_alert_channel_ok"]
      slackChannelFail    = var.org["backup_alert_channel_fail"]
    }
  }
  tracing_config {
    mode = "Active"
  }
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
}

## IAM

resource "aws_iam_role" "dit_backup" {
  provider           = aws.master
  name               = "dit-aws-backup"
  description        = "Role used by AWS Backup for performing backups."
  assume_role_policy = data.aws_iam_policy_document.dit_backup.json
}

data "aws_iam_policy_document" "dit_backup" {
  provider = aws.master
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "dit_backup" {
  provider    = aws.master
  name        = "dit-aws-backup"
  description = "Policy used by AWS Backup role for performing backups."
  policy      = file("${path.module}/policies/backup-policy.json")
}

resource "aws_iam_role_policy_attachment" "dit_backup_aws_linked_role_policy" {
  provider   = aws.master
  role       = aws_iam_role.dit_backup.name
  policy_arn = aws_iam_policy.dit_backup.arn
}

resource "aws_iam_role" "aws_backup_to_slack" {
  provider           = aws.master
  name               = "aws-backup-to-slack"
  assume_role_policy = data.aws_iam_policy_document.aws_backup_to_slack.json
}

data "aws_iam_policy_document" "aws_backup_to_slack" {
  provider = aws.master
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "aws_backup_to_slack_lambda_execution_cloudwatch" {
  provider    = aws.master
  name        = "AWSLambdaBasicExecutionRole-aws_backup_to_slack-cloudwatch"
  description = "Allow Lambda to create and update CloudWatch log streams and events"
  policy      = data.aws_iam_policy_document.aws_backup_to_slack_lambda_execution_cloudwatch.json
}

data "aws_iam_policy_document" "aws_backup_to_slack_lambda_execution_cloudwatch" {
  provider = aws.master
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.aws_backup_to_slack.arn}:*"]
  }
}

resource "aws_iam_role_policy_attachment" "aws_backup_to_slack_lambda_execution_cloudwatch" {
  provider   = aws.master
  role       = aws_iam_role.aws_backup_to_slack.name
  policy_arn = aws_iam_policy.aws_backup_to_slack_lambda_execution_cloudwatch.arn
}

resource "aws_iam_policy" "aws_backup_to_slack_lambda_execution_kms" {
  provider    = aws.master
  name        = "AWSLambdaBasicExecutionRole-aws_backup_to_slack-kms"
  description = "Allow Lambda to decrypt environment variables using KMS"
  policy      = data.aws_iam_policy_document.aws_backup_to_slack_lambda_execution_kms.json
}

data "aws_iam_policy_document" "aws_backup_to_slack_lambda_execution_kms" {
  provider = aws.master
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", ]
    resources = ["arn:aws:kms:*:${data.aws_caller_identity.master.account_id}:key/*"]
  }
}

resource "aws_iam_role_policy_attachment" "aws_backup_to_slack_lambda_execution_kms" {
  provider   = aws.master
  role       = aws_iam_role.aws_backup_to_slack.name
  policy_arn = aws_iam_policy.aws_backup_to_slack_lambda_execution_kms.arn
}

## CloudWatch

resource "aws_cloudwatch_log_group" "aws_backup_to_slack" {
  provider          = aws.master
  name              = "/aws/lambda/${aws_lambda_function.aws_backup_to_slack.function_name}"
  #checkov:skip=CKV_AWS_338:Ensure CloudWatch log groups retains logs for at least 1 year
  #checkov:skip=CKV_AWS_158:Ensure that CloudWatch Log Group is encrypted by KMS
  retention_in_days = 60
}
