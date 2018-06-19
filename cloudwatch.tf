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

resource "aws_cloudwatch_event_permission" "member" {
  provider = "aws.master"
  principal = "${data.aws_caller_identity.master.account_id}"
  statement_id = "account-${data.aws_caller_identity.master.account_id}"
}

resource "aws_cloudwatch_event_rule" "member" {
  provider = "aws.member"
  name = "rule-${data.aws_caller_identity.member.account_id}"
  event_pattern = "{\"account\": [\"${data.aws_caller_identity.member.account_id}\"]}"
}

resource "aws_cloudwatch_event_target" "member" {
  provider = "aws.member"
  arn = "${aws_cloudwatch_log_group.master.arn}"
  rule = "${aws_cloudwatch_event_rule.member.name}"
  target_id = "org-member-${data.aws_caller_identity.member.account_id}"
}
