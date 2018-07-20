resource "aws_guardduty_detector" "master" {
  provider = "aws.master"
  enable = true
}

resource "aws_sns_topic" "guardduty_sns" {
  provider = "aws.master"
  name = "org-guardduty-sns"
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  provider = "aws.master"
  name = "org-rule-guardduty"
  event_pattern = "{\"source\":[\"aws.guardduty\"],\"detail-type\":[\"GuardDutyFinding\"]}"
}

resource "aws_cloudwatch_event_target" "guardduty" {
  provider = "aws.master"
  arn = "${aws_sns_topic.guardduty_sns.arn}"
  rule = "${aws_cloudwatch_event_rule.guardduty.name}"
}
