# Setup CloudTrail on AWS Org account
resource "aws_cloudtrail" "trail" {
  provider                   = aws.master
  name                       = "cloudtrail-${data.aws_caller_identity.master.account_id}"
  enable_logging             = true
  is_multi_region_trail      = true
  is_organization_trail      = true
  enable_log_file_validation = true
  kms_key_id                 = aws_kms_key.cloudtrail-kms.arn
  s3_bucket_name             = aws_s3_bucket.cloudtrail-s3.id
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_log.arn
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
  provider          = aws.master
  name              = "cloudtrail-${data.aws_caller_identity.master.account_id}"
  retention_in_days = 7
}

resource "aws_iam_role" "cloudtrail_log" {
  provider           = aws.master
  name               = "cloudtrail_log"
  assume_role_policy = file("${path.module}/policies/cloudtrail-sts.json")
}

resource "aws_iam_role_policy" "cloudtrail_log_policy" {
  provider = aws.master
  name     = "cloudtrail_log"
  role     = aws_iam_role.cloudtrail_log.id
  policy = templatefile("${path.module}/policies/cloudtrail-role.json",
    {
      cloudtrail_log_stream = aws_cloudwatch_log_group.cloudtrail.arn
    }
  )
}

resource "aws_s3_bucket" "cloudtrail-s3" {
  provider = aws.master
  bucket   = "cloudtrail-${data.aws_caller_identity.master.account_id}"
  tags = {
    "website" = "false"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail-s3_block_public_access" {
  provider                = aws.master
  bucket                  = aws_s3_bucket.cloudtrail-s3.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail-s3_sse" {
  provider = aws.master
  bucket   = aws_s3_bucket.cloudtrail-s3.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail-s3-policy" {
  provider = aws.master
  bucket   = aws_s3_bucket.cloudtrail-s3.id
  policy = templatefile("${path.module}/policies/cloudtrail-s3.json",
    {
      cloudtrail_s3   = "cloudtrail-${data.aws_caller_identity.master.account_id}"
      account_id      = data.aws_caller_identity.master.account_id
      organization_id = local.aws_organization_id
    }
  )
}

resource "aws_kms_key" "cloudtrail-kms" {
  provider    = aws.master
  description = "CloudTrail KMS Key"
  policy = templatefile("${path.module}/policies/cloudtrail-kms.json",
    {
      aws_account_id = data.aws_caller_identity.master.account_id
    }
  )
}

resource "aws_cloudtrail" "sentinel-trail" {
  provider                   = aws.master
  name                       = "sentinel-cloudtrail-${data.aws_caller_identity.master.account_id}"
  enable_logging             = true
  is_multi_region_trail      = true
  is_organization_trail      = true
  enable_log_file_validation = true
  kms_key_id                 = aws_kms_key.sentinel_guard_duty.arn
  s3_bucket_name             = aws_s3_bucket.sentinel_logs.id
  s3_key_prefix              = local.sentinel_cloudtrail_folder
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
