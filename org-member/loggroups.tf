# Create log groups for accounts.
# At time of writing (29th Feb 2024) I wasn't sure if we wanted to roll this out to all accounts.
# So I've added in a 'count' to act as an if statement. 
# e.g. if var.member.createloggroups == true, set count to 1 and create the resource. 

resource "aws_iam_role" "CWLtoSubscriptionFilterRole" {
  count    = try(var.member.createloggroups == true ? 1 : 0, 0)
  name     = "CWLtoSubscriptionFilterRole"
  provider = aws.member

  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    "Statement" : {
      "Effect" : "Allow",
      "Principal" : { "Service" : "logs.amazonaws.com" },
      "Action" : "sts:AssumeRole"
    }
  })
}

resource "aws_iam_policy" "Permissions-Policy-For-CWL-Subscription-filter" {
  count    = try(var.member.createloggroups == true ? 1 : 0, 0)
  name     = "Permissions-Policy-For-CWL-Subscription-filter"
  provider = aws.member
  path     = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:PutLogEvents",
        "Resource" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.member.account_id}:log-group:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "Permissions-Policy-For-CWL-Subscription-filter" {
  count      = try(var.member.createloggroups == true ? 1 : 0, 0)
  provider   = aws.member
  role       = aws_iam_role.CWLtoSubscriptionFilterRole[0].name
  policy_arn = aws_iam_policy.Permissions-Policy-For-CWL-Subscription-filter[0].arn
}

resource "aws_ssm_parameter" "central_log_groups" {
  count    = try(var.member.createloggroups == true ? 1 : 0, 0)
  provider = aws.member
  name     = "/copilot/tools/central_log_groups"
  type     = "String"
  value = jsonencode({
    "prod" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.logarchive.account_id}:destination:cwl_log_destination",
    "dev" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.logarchive.account_id}:destination:cwl_log_destination"
  })
}
