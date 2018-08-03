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
