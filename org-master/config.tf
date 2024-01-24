# Setup Config on AWS Org account

resource "aws_s3_bucket" "master_config_bucket" {
  provider = aws.master
  bucket = "aws-config-${data.aws_caller_identity.master.account_id}"
  tags = {
    "website" = "false"
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket_block_public_access" {
  provider = aws.master
  bucket = aws_s3_bucket.master_config_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "master_config_bucket_sse" {
  provider = aws.master
  bucket = aws_s3_bucket.master_config_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
