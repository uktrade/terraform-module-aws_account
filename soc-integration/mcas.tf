// configuration as per: https://docs.microsoft.com/en-us/cloud-app-security/connect-aws-to-microsoft-cloud-app-security

resource "aws_iam_access_key" "access_key" {
  provider = aws.member
  user    = aws_iam_user.user.name
}

resource "aws_iam_user" "user" {
  provider = aws.member
  name = "CloudAppSecurityAWS"
  path = "/"
}

resource "aws_iam_policy" "cloudappsecurity_policy" {
  provider = aws.member
  name = "CloudAppSecurityPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
        "Action" : [
          "cloudtrail:DescribeTrails",
          "cloudtrail:LookupEvents",
          "cloudtrail:GetTrailStatus",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "iam:List*",
          "iam:Get*",
          "s3:ListAllMyBuckets",
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
   })
}

resource "aws_iam_user_policy_attachment" "cloudappsecurity_policy" {
  provider = aws.member
  user = aws_iam_user.user.name
  policy_arn = aws_iam_policy.cloudappsecurity_policy.arn
}

resource "aws_iam_user_policy_attachment" "security-hub-policy" {
  provider = aws.member
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "security-audit-policy" {
  provider = aws.member
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

output "mcas_access_key_id" {
  value = aws_iam_access_key.access_key.id
}

output "mcas_access_key_secret" {
  value = aws_iam_access_key.access_key.secret
}
