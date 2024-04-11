# Setup Config on AWS Org account

resource "aws_s3_bucket" "master_config_bucket" {
  provider = aws.master
  bucket   = "aws-config-${data.aws_caller_identity.master.account_id}"
  tags = {
    "website" = "false"
  }
  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #checkov:skip=CKV_AWS_21:Ensure all data stored in the S3 bucket have versioning enabled
  #checkov:skip=CKV2_AWS_61:Ensure that an S3 bucket has a lifecycle configuration
  #checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled
  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
}

# resource "aws_s3_bucket_logging" "master_config_bucket_logging" {
#   bucket = aws_s3_bucket.master_config_bucket.id

#   target_bucket = aws_s3_bucket.log_bucket.id
#   target_prefix = "log/"
# }

# KMS Key to be created which will be used here
# resource "aws_s3_bucket_server_side_encryption_configuration" "good_sse_1" {
#   bucket = aws_s3_bucket.master_config_bucket.bucket

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.cloudtrail-kms.arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }

resource "aws_s3_bucket_public_access_block" "config_bucket_block_public_access" {
  provider                = aws.master
  bucket                  = aws_s3_bucket.master_config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "master_config_bucket_sse" {
  provider = aws.master
  bucket   = aws_s3_bucket.master_config_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
