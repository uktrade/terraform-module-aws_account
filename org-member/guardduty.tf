# Setup GuardDuty on AWS Org member account
resource "aws_guardduty_detector" "member" {
  provider = aws.member
  enable = true
}

resource "aws_guardduty_member" "org" {
  provider = aws.master
  account_id = aws_guardduty_detector.member.account_id
  detector_id = var.org["guardduty_id"]
  email = var.member["email"]
  invite = true
}

resource "aws_cloudwatch_event_target" "guardduty" {
  provider = aws.member
  arn = var.org["cloudwatch_eventbus_arn"]
  rule = aws_cloudwatch_event_rule.guardduty.name
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  provider = aws.member
  name = "rule-guardduty-${data.aws_caller_identity.member.account_id}"
  event_pattern = <<INPUT
    {
      "source": ["aws.guardduty"],
      "detail-type": ["GuardDuty Finding"]
    }
INPUT
}
