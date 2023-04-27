# Setup Config on AWS Org member account

resource "aws_s3_bucket" "config_bucket" {
  provider = aws.member
  bucket = "aws-config-${data.aws_caller_identity.member.account_id}"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    "website" = "false"
  }
}
