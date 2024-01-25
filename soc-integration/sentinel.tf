// configuration as per: https://docs.microsoft.com/en-us/azure/sentinel/connect-aws

resource "aws_iam_role" "azure_sentinel" {
  provider    = aws.member
  name        = "AzureSentinelRole"
  description = "Role used by the Sentinel legacy CloudTrail connector (https://docs.microsoft.com/en-us/azure/sentinel/connect-aws?tabs=ct)"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.config["sentinel_account_id"]}:root"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : var.config["sentinel_workspace_id"]
          }
        }
      }
    ]
  })
}

data "aws_iam_policy" "cloudtrail_readonly" {
  provider = aws.member
  name     = var.member["cloudtrail_readonly_policy"]
}

resource "aws_iam_role_policy_attachment" "cloudtrail_readonly" {
  provider   = aws.member
  role       = aws_iam_role.azure_sentinel.name
  policy_arn = data.aws_iam_policy.cloudtrail_readonly.arn
}

output "azure-sentinel-role-arn" {
  value = aws_iam_role.azure_sentinel.arn
}
