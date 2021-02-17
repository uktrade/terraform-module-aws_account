# Setup GuardDuty on AWS Org account
resource "aws_guardduty_detector" "master" {
  provider = aws.master
  enable = true
}

resource "aws_sns_topic" "guardduty_sns" {
  provider = aws.master
  name = "org-guardduty-sns"
}

resource "aws_sns_topic_policy" "guardduty_sns" {
  provider = aws.master
  arn = aws_sns_topic.guardduty_sns.id
  policy = data.aws_iam_policy_document.guardduty_sns.json
}

data "aws_iam_policy_document" "guardduty_sns" {
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
    resources = [aws_sns_topic.guardduty_sns.id]
  }

  statement {
    sid = "Allow CloudWatch Events to publish"
    actions = ["SNS:Publish"]
    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.guardduty_sns.id]
  }
}

resource "aws_cloudwatch_event_target" "guardduty" {
  provider = aws.master
  arn = aws_sns_topic.guardduty_sns.arn
  rule = aws_cloudwatch_event_rule.guardduty.name
  input_transformer {
      input_paths = {
      source = "$.source"
      awsAccountId = "$.detail.accountId"
      awsRegion = "$.detail.region"
      type = "$.detail.type"
      resourceType = "$.detail.resource.resourceType"
      actionType = "$.detail.service.action.actionType"
      severity = "$.detail.severity"
      arn = "$.detail.arn"
      time = "$.time"
    }
    input_template = <<INPUT
    [{
      "title": "Severity <severity> - <type>/<resourceType> <actionType>",
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
          "title": "Type",
          "value": "<type>/<resourceType>",
          "short": "true"
        },{
          "title": "Action",
          "value": "<actionType>",
          "short": "true"
        },{
          "title": "Severity",
          "value": "<severity>",
          "short": "true"
        },{
          "title": "ARN",
          "value": "<arn>",
          "short": "true"
        },{
          "title": "Timestamp",
          "value": "<time>",
          "short": "true"
        }],
      "fallback": "Severity <severity> - <type>/<resourceType> <actionType>"
    }]
INPUT
  }
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  provider = aws.master
  name = "org-rule-guardduty"
  event_pattern = <<INPUT
    {
      "source": ["aws.guardduty"],
      "detail-type": ["GuardDuty Finding"]
    }
INPUT
}
