// configuration as per: https://docs.microsoft.com/en-us/cloud-app-security/connect-aws-to-microsoft-cloud-app-security

resource "aws_iam_access_key" "access_key" {
  provider = aws.member
  user     = aws_iam_user.user.name
}

resource "aws_iam_user" "user" {
  provider = aws.member
  name     = "CloudAppSecurityAWS"
  path     = "/"
  #checkov:skip=CKV_AWS_273:Ensure access is controlled through SSO and not AWS IAM defined users
}

resource "aws_iam_policy" "cloudappsecurity_policy" {
  provider = aws.member
  name     = "CloudAppSecurityPolicy"
  #checkov:skip=CKV_AWS_289:Ensure IAM policies does not allow permissions management / resource exposure without constraints
  #checkov:skip=CKV_AWS_355:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
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
  provider   = aws.member
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.cloudappsecurity_policy.arn
  #checkov:skip=CKV_AWS_40:Ensure IAM policies are attached only to groups or roles (Reducing access management complexity may in-turn reduce opportunity for a principal to inadvertently receive or retain excessive privileges.)
}

resource "aws_iam_user_policy_attachment" "security-hub-policy" {
  provider   = aws.member
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"
  #checkov:skip=CKV_AWS_40:Ensure IAM policies are attached only to groups or roles (Reducing access management complexity may in-turn reduce opportunity for a principal to inadvertently receive or retain excessive privileges.)
}

resource "aws_iam_user_policy_attachment" "security-audit-policy" {
  provider   = aws.member
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  #checkov:skip=CKV_AWS_40:Ensure IAM policies are attached only to groups or roles (Reducing access management complexity may in-turn reduce opportunity for a principal to inadvertently receive or retain excessive privileges.)
}

output "mcas_access_key_id" {
  value = aws_iam_access_key.access_key.id
}

output "mcas_access_key_secret" {
  value = aws_iam_access_key.access_key.secret
}
