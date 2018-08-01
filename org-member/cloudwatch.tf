resource "aws_cloudwatch_event_permission" "master" {
  provider = "aws.master"
  principal = "${data.aws_caller_identity.member.account_id}"
  statement_id = "account-${data.aws_caller_identity.member.account_id}"
}

resource "aws_cloudwatch_event_permission" "master-config" {
  provider = "aws.master.config"
  principal = "${data.aws_caller_identity.member.account_id}"
  statement_id = "account-${data.aws_caller_identity.member.account_id}"
}

resource "aws_cloudwatch_event_rule" "member" {
  provider = "aws.member"
  name = "rule-${data.aws_caller_identity.member.account_id}"
  event_pattern = "{\"account\": [\"${data.aws_caller_identity.member.account_id}\"]}"
}

resource "aws_cloudwatch_event_target" "member" {
  provider = "aws.member"
  arn = "${var.org["cloudwatch_eventbus_arn"]}"
  rule = "${aws_cloudwatch_event_rule.member.name}"
  target_id = "org-member-${data.aws_caller_identity.member.account_id}"
}

resource "aws_cloudwatch_event_target" "config" {
  provider = "aws.member.config"
  arn = "arn:aws:events:${data.aws_region.master_config.name}:${data.aws_caller_identity.master.account_id}:event-bus/default"
  rule = "${aws_cloudwatch_event_rule.config.name}"
  target_id = "org-config-${data.aws_caller_identity.member.account_id}"
}

resource "aws_cloudwatch_event_rule" "config" {
  provider = "aws.member.config"
  name = "rule-config-${data.aws_caller_identity.member.account_id}"
  event_pattern = <<INPUT
    {
      "source": [
        "aws.config"
      ],
      "detail-type": [
        "Config Rules Compliance Change"
      ],
      "detail": {
        "messageType": [
          "ComplianceChangeNotification"
        ]
      }
    }
  INPUT
}
