// configuration as per: https://docs.microsoft.com/en-us/azure/sentinel/connect-aws

resource "aws_iam_role" "azure_sentinel" {
  provider = aws.member
  name = "AzureSentinelRole"

  assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.config["sentinel_account_id"]}:root"
    },
    "Action": "sts:AssumeRole",
    "Condition": {
      "StringEquals": {
        "sts:ExternalId": var.config["sentinel_workspace_id"]
      }
    }
  }
  ]
})
}

resource "aws_iam_role_policy_attachment" "cloudtrail_readonly" {
  provider = aws.member
  role = aws_iam_role.azure_sentinel.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrailReadOnlyAccess"
}

output "azure-sentinel-role-arn" {
  value = aws_iam_role.azure_sentinel.arn
}
