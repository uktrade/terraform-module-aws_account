# Setup CloudTrail on AWS Org member account
resource "aws_cloudtrail" "trail" {
  provider                   = aws.member
  name                       = "cloudtrail-${data.aws_caller_identity.member.account_id}"
  enable_logging             = true
  is_multi_region_trail      = true
  enable_log_file_validation = true
  kms_key_id                 = aws_kms_key.cloudtrail-kms.arn
  s3_bucket_name             = aws_s3_bucket.cloudtrail-s3.id
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_log.arn
  #checkov:skip=CKV_AWS_252:Ensure CloudTrail defines an SNS Topic
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  provider          = aws.member
  name              = "cloudtrail-${data.aws_caller_identity.member.account_id}"
  retention_in_days = 7
  #checkov:skip=CKV_AWS_338:Ensure CloudWatch log groups retains logs for at least 1 year
  #checkov:skip=CKV_AWS_158:Ensure that CloudWatch Log Group is encrypted by KMS
}

resource "aws_iam_role" "cloudtrail_log" {
  provider           = aws.member
  name               = "cloudtrail_log"
  assume_role_policy = file("${path.module}/policies/cloudtrail-sts.json")
}

resource "aws_iam_role_policy" "cloudtrail_log_policy" {
  provider = aws.member
  name     = "cloudtrail_log"
  role     = aws_iam_role.cloudtrail_log.id
  policy = templatefile("${path.module}/policies/cloudtrail-role.json",
    {
      cloudtrail_log_stream = aws_cloudwatch_log_group.cloudtrail.arn
    }
  )
}

resource "aws_s3_bucket" "cloudtrail-s3" {
  provider = aws.member
  bucket   = "cloudtrail-${data.aws_caller_identity.member.account_id}"
  tags = {
    "website" = "false"
  }
  #checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
  #checkov:skip=CKV2_AWS_61:Ensure that an S3 bucket has a lifecycle configuration
  #checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  # The bucket has been encrypted but checkov is not detecting this
  #checkov:skip=CKV_AWS_144:Ensure that S3 bucket has cross-region replication enabled
  #checkov:skip=CKV_AWS_145:Ensure that S3 buckets are encrypted with KMS by default
}

resource "aws_s3_bucket_versioning" "cloudtrail-s3-versioning" {
  bucket = aws_s3_bucket.cloudtrail-s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail-s3-encryption" {
  bucket = aws_s3_bucket.cloudtrail-s3.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail-kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail-s3_block_public_access" {
  provider                = aws.member
  bucket                  = aws_s3_bucket.cloudtrail-s3.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail-s3_sse" {
  provider = aws.member
  bucket   = aws_s3_bucket.cloudtrail-s3.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail-s3-policy" {
  provider = aws.member
  bucket   = aws_s3_bucket.cloudtrail-s3.id
  policy = templatefile("${path.module}/policies/cloudtrail-s3.json",
    {
      cloudtrail_s3 = "cloudtrail-${data.aws_caller_identity.member.account_id}"
    }
  )
}

resource "aws_kms_key" "cloudtrail-kms" {
  provider            = aws.member
  description         = "CloudTrail KMS Key"
  enable_key_rotation = var.member["cloudtrail_kms_key_rotation"]
  policy = templatefile("${path.module}/policies/cloudtrail-kms.json",
    {
      aws_account_id = data.aws_caller_identity.member.account_id
    }
  )
}
