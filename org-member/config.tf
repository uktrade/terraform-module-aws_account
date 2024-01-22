# Setup Config on AWS Org member account

resource "aws_s3_bucket" "config_bucket" {
  provider = aws.member
  bucket = "aws-config-${data.aws_caller_identity.member.account_id}"
  tags = {
    "website" = "false"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_sse" {
  provider = aws.member
  bucket = aws_s3_bucket.config_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "deny_non_https_access" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = data.aws_iam_policy_document.deny_non_https_access.json
  provider = aws.member
}

data "aws_iam_policy_document" "deny_non_https_access" {
   statement {
    sid = "Deny non-HTTPS access."
    actions = ["s3:*"]
    effect = "Deny"
    resources = ["${aws_s3_bucket.config_bucket.arn}/*"]
    principals {
      type = "*"
      identifiers = ["*"]
    }
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
  }
}