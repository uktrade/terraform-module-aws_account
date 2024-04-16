# Setup CloudWatch on AWS Org account
resource "aws_cloudwatch_log_group" "master" {
  provider          = aws.master
  name              = "org"
  kms_key_id        = aws_kms_key.cloudwatch.arn
  #checkov:skip=CKV_AWS_338:Ensure CloudWatch log groups retains logs for at least 1 year
  retention_in_days = 7
}

resource "aws_kms_key" "cloudwatch" {
  provider    = aws.master
  description = "CloudWatch Key"
  policy = templatefile("${path.module}/policies/cloudwatch-kms.json",
    {
      aws_account_id = data.aws_caller_identity.master.account_id,
      aws_region     = data.aws_region.master.name
    }
  )
  #checkov:skip=CKV_AWS_7: "Ensure rotation for customer created CMKs is enabled" 
}

data "aws_cloudwatch_event_bus" "default" {
  provider = aws.master
  name     = "default"
}

data "aws_iam_policy_document" "default_event_bus_policy" {
  provider = aws.master
  statement {
    sid       = "MemberAccountAccess"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [data.aws_cloudwatch_event_bus.default.arn]
    principals {
      type        = "AWS"
      identifiers = [for id in data.aws_organizations_organization.master.non_master_accounts[*].id :
        "arn:aws:iam::${id}:root"
      ]
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "default" {
  provider       = aws.master
  policy         = data.aws_iam_policy_document.default_event_bus_policy.json
  event_bus_name = data.aws_cloudwatch_event_bus.default.name
}
