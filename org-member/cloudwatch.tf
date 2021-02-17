# Setup CloudWatch on AWS Org member account
resource "aws_cloudwatch_event_permission" "master" {
  provider = aws.master
  principal = data.aws_caller_identity.member.account_id
  statement_id = "account-${data.aws_caller_identity.member.account_id}"
}

resource "aws_cloudwatch_event_rule" "member" {
  provider = aws.member
  name = "org-rule-member-${data.aws_caller_identity.member.account_id}"
  event_pattern = "{\"account\": [\"${data.aws_caller_identity.member.account_id}\"]}"
}

resource "aws_cloudwatch_event_target" "member" {
  provider = aws.member
  arn = var.org["cloudwatch_eventbus_arn"]
  rule = aws_cloudwatch_event_rule.member.name
}
