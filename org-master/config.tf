# Setup Config on AWS Org account
resource "aws_iam_role" "master_config_role" {
  provider = aws.master
  name = "config-role"
  assume_role_policy = data.aws_iam_policy_document.master_config_sts.json
}

data "aws_iam_policy_document" "master_config_sts" {
  statement {
    sid = "DefaultPolicyForAWSConfig"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config_organization" {
  provider = aws.master
  role = aws_iam_role.master_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "master" {
  provider = aws.master
  name = "aws-org-config"
  organization_aggregation_source {
    all_regions = true
    role_arn = aws_iam_role.master_config_role.arn
  }
  depends_on = [aws_iam_role_policy_attachment.config_organization]
}

resource "aws_config_configuration_recorder" "master_config" {
  provider = aws.master
  name = "config-${data.aws_caller_identity.master.account_id}"
  role_arn = aws_iam_role.master_config_role.arn
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role_policy_attachment" "master_config_policy" {
  provider = aws.master
  role = aws_iam_role.master_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_policy" "master_config_service_policy" {
  provider = aws.master
  name = "master_config_service_policy"
  policy = file("${path.module}/policies/config-svc.json")
}

resource "aws_iam_role_policy_attachment" "master_config_service_policy" {
  provider = aws.master
  role = aws_iam_role.master_config_role.name
  policy_arn = aws_iam_policy.master_config_service_policy.id
}

resource "aws_s3_bucket" "master_config_bucket" {
  provider = aws.master
  bucket = "aws-config-${data.aws_caller_identity.master.account_id}"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    "website" = "false"
  }
}

data "template_file" "config_s3_policy" {
  template = file("${path.module}/policies/config-s3.json")
  vars = {
    config_s3_arn = aws_s3_bucket.master_config_bucket.arn
  }
}

resource "aws_iam_role_policy" "config_s3_policy" {
  provider = aws.master
  name = "config_s3_policy"
  role = aws_iam_role.master_config_role.name
  policy = data.template_file.config_s3_policy.rendered
}

resource "aws_config_configuration_recorder_status" "master_config" {
  provider = aws.master
  name = aws_config_configuration_recorder.master_config.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.master]
}

resource "aws_config_delivery_channel" "master" {
  provider = aws.master
  name = "aws-config-${data.aws_caller_identity.master.account_id}"
  s3_bucket_name = aws_s3_bucket.master_config_bucket.id
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
  depends_on = [aws_config_configuration_recorder.master_config]
}

resource "aws_sns_topic" "config_sns" {
  provider = aws.master
  name = "org-config-sns"
}

resource "aws_sns_topic_policy" "config_sns" {
  provider = aws.master
  arn = aws_sns_topic.config_sns.id
  policy = data.aws_iam_policy_document.config_sns_policy.json
}

data "aws_iam_policy_document" "config_sns_policy" {
  provider = aws.master
  statement {
    sid = "Default SNS policy"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    condition {
      test = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [data.aws_caller_identity.master.account_id]
    }
    resources = [aws_sns_topic.config_sns.id]
  }

  statement {
    sid = "Allow AWS Config to publish events"
    actions = ["SNS:Publish"]
    principals {
      type = "AWS"
      identifiers = [aws_iam_role.master_config_role.arn]
    }
    resources = [aws_sns_topic.config_sns.id]
  }

  statement {
    sid = "Allow CloudWatch Events to publish"
    actions = ["SNS:Publish"]
    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.config_sns.id]
  }
}

resource "aws_iam_role_policy" "config_sns_policy" {
  provider = aws.master
  name = "config_sns_policy"
  role = aws_iam_role.master_config_role.name
  policy = data.aws_iam_policy_document.config_sns.json
}

data "aws_iam_policy_document" "config_sns" {
  provider = aws.master
  statement {
    sid = "DefaultPolicyForAWSConfig"
    actions = ["SNS:Publish"]
    resources = [aws_sns_topic.config_sns.id]
  }
}

resource "aws_cloudwatch_event_target" "config" {
  provider = aws.master
  arn = aws_sns_topic.config_sns.arn
  rule = aws_cloudwatch_event_rule.config.name
  input_transformer {
    input_paths = {
      source = "$.source"
      complianceType = "$.detail.newEvaluationResult.complianceType"
      configRuleName = "$.detail.configRuleName"
      awsAccountId = "$.detail.awsAccountId"
      awsRegion = "$.detail.awsRegion"
      resourceType = "$.detail.resourceType"
      resourceId = "$.detail.resourceId"
      time = "$.time"
    }
    input_template = <<INPUT
[{
  "title": "<resourceType> <resourceId> <complianceType>",
  "author_name": "<source>",
  "fields": [{
      "title": "Account ID",
      "value": "<awsAccountId>",
      "short": "true"
    },{
      "title": "Region",
      "value": "<awsRegion>",
      "short": "true"
    },{
      "title": "Resource Type",
      "value": "<resourceType>",
      "short": "true"
    },{
      "title": "Resource ID",
      "value": "<resourceId>",
      "short": "true"
    },{
      "title": "Config Rule",
      "value": "<configRuleName>",
      "short": "true"
    },{
      "title": "Compliance Status",
      "value": "<complianceType>",
      "short": "true"
    },{
      "title": "Timestamp",
      "value": "<time>",
      "short": "true"
    }],
  "fallback": "<resourceType> <resourceId> <complianceType>"
}]
INPUT
  }
}

resource "aws_cloudwatch_event_rule" "config" {
  provider = aws.master
  name = "org-rule-config"
  event_pattern = <<INPUT
    {
      "source": [
        "aws.config"
      ],
      "detail-type": [
        "Config Rules Compliance Change"
      ]
    }
INPUT
}
