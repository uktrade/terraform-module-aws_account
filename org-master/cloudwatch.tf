resource "aws_cloudwatch_log_group" "master" {
  provider = "aws.master"
  name = "org"
  kms_key_id = "${aws_kms_key.cloudwatch.arn}"
}

resource "aws_kms_key" "cloudwatch" {
  provider = "aws.master"
  description = "CloudWatch Key"
  policy = "${data.template_file.cloudwatch-kms-policy.rendered}"
}

data "template_file" "cloudwatch-kms-policy" {
  template = "${file("${path.module}/policies/cloudwatch-kms.json")}"
  vars {
    aws_account_id = "${data.aws_caller_identity.master.account_id}"
    aws_region = "${data.aws_region.master.name}"
  }
}

resource "aws_cloudwatch_event_target" "config" {
  provider = "aws.master.config"
  arn = "${aws_sns_topic.config_sns.arn}"
  rule = "${aws_cloudwatch_event_rule.config.name}"
  target_id = "org-config-${data.aws_caller_identity.master.account_id}"
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
            "short": true
          },{
            "title": "Region",
            "value": "<awsRegion>",
            "short": true
          },{
            "title": "Resource Type",
            "value": "<resourceType>",
            "short": true
          },{
            "title": "Resource ID",
            "value": "<resourceId>",
            "short": true
          },{
            "title": "Config Rule",
            "value": "<configRuleName>",
            "short": true
          },{
            "title": "Compliance Status",
            "value": "<complianceType>",
            "short": true
          },{
            "title": "Timestamp",
            "value": "<time>",
            "short": true
          }
        ],
        "fallback": "<resourceType> <resourceId> <complianceType>",
      }]
    INPUT
  }
}

resource "aws_cloudwatch_event_rule" "config" {
  provider = "aws.master.config"
  name = "rule-config-${data.aws_caller_identity.master.account_id}"
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
