# AWS Backup

data "aws_kms_key" "aws_backup" {
  provider = aws.member
  key_id   = "alias/aws/backup"
}

resource "aws_backup_vault" "daily8_weekly5_monthly14" {
  provider    = aws.member
  name        = "daily8-weekly5-monthly14"
  kms_key_arn = data.aws_kms_key.aws_backup.arn
}

resource "aws_organizations_policy_attachment" "backup_daily8_weekly5_monthly14" {
  provider  = aws.master
  policy_id = var.org["organization_policy_backup_d8w5m14"]
  target_id = data.aws_caller_identity.member.account_id
}

# Alerting

resource "aws_backup_vault_notifications" "daily8_weekly5_monthly14" {
  provider            = aws.member
  backup_vault_name   = aws_backup_vault.daily8_weekly5_monthly14.name
  sns_topic_arn       = aws_sns_topic.org_backup_sns.arn
  backup_vault_events = ["BACKUP_JOB_COMPLETED"]
}

## SNS

resource "aws_sns_topic" "org_backup_sns" {
  provider = aws.member
  name     = "org-backup-sns"
}

resource "aws_sns_topic_policy" "org_backup_sns" {
  provider = aws.member
  arn      = aws_sns_topic.org_backup_sns.id
  policy   = data.aws_iam_policy_document.org_backup_sns.json
}

resource "aws_sns_topic_subscription" "org_backup_sns_to_lambda" {
  provider  = aws.master
  topic_arn = aws_sns_topic.org_backup_sns.arn
  protocol  = "lambda"
  endpoint  = var.org["backup_to_slack_lambda_arn"]
  depends_on = [
    aws_sns_topic_policy.org_backup_sns
  ]
}

## Lambda

resource "aws_lambda_permission" "aws_lambda_from_member_sns" {
  provider      = aws.master
  statement_id  = "AllowExecutionFromMember_${data.aws_caller_identity.member.account_id}"
  principal     = "sns.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = var.org["backup_to_slack_lambda_arn"]
  source_arn    = aws_sns_topic.org_backup_sns.arn
}

## IAM

resource "aws_iam_role" "dit_backup" {
  provider           = aws.member
  name               = "dit-aws-backup"
  description        = "Role used by AWS Backup for performing backups."
  assume_role_policy = data.aws_iam_policy_document.dit_backup.json
}

data "aws_iam_policy_document" "dit_backup" {
  provider = aws.member
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
  provider    = aws.member
  name        = "dit-aws-backup"
  description = "Policy used by AWS Backup role for performing backups."
  policy      = file("${path.module}/policies/backup-policy.json")
}

resource "aws_iam_role_policy_attachment" "dit_backup_aws_linked_role_policy" {
  provider   = aws.member
  role       = aws_iam_role.dit_backup.name
  policy_arn = aws_iam_policy.dit_backup.arn
}

data "aws_iam_policy_document" "org_backup_sns" {
  provider = aws.member
  statement {
    sid     = "org_backup_sns"
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    resources = [aws_sns_topic.org_backup_sns.id]
  }
  statement {
    sid     = "AllowSubscriptionFromMasterAccount"
    effect  = "Allow"
    actions = ["SNS:Receive", "SNS:Subscribe"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.master.account_id}:root"]
    }
    resources = [aws_sns_topic.org_backup_sns.id]
  }
}
