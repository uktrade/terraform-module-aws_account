# Setup CloudTrail on AWS Org account
resource "aws_cloudtrail" "trail" {
  provider = aws.master
  name = "cloudtrail-${data.aws_caller_identity.master.account_id}"
  enable_logging = true
  is_multi_region_trail = true
  is_organization_trail = true
  enable_log_file_validation = true
  kms_key_id = aws_kms_key.cloudtrail-kms.arn
  s3_bucket_name = aws_s3_bucket.cloudtrail-s3.id
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail_log.arn
  event_selector {
    read_write_type = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }

    data_resource {
      type = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  provider = aws.master
  name = "cloudtrail-${data.aws_caller_identity.master.account_id}"
  retention_in_days = 7
}

resource "aws_iam_role" "cloudtrail_log" {
  provider = aws.master
  name = "cloudtrail_log"
  assume_role_policy = file("${path.module}/policies/cloudtrail-sts.json")
}

resource "aws_iam_role_policy" "cloudtrail_log_policy" {
  provider = aws.master
  name = "cloudtrail_log"
  role = aws_iam_role.cloudtrail_log.id
  policy = data.template_file.cloudtrail-policy.rendered
}

data "template_file" "cloudtrail-policy" {
  template = file("${path.module}/policies/cloudtrail-role.json")
  vars = {
    cloudtrail_log_stream = aws_cloudwatch_log_group.cloudtrail.arn
  }
}

resource "aws_s3_bucket" "cloudtrail-s3" {
  provider = aws.master
  bucket = "cloudtrail-${data.aws_caller_identity.master.account_id}"
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
  policy = data.template_file.cloudtrail-s3.rendered
}

data "template_file" "cloudtrail-s3" {
  template = file("${path.module}/policies/cloudtrail-s3.json")
  vars = {
    cloudtrail_s3 = "cloudtrail-${data.aws_caller_identity.master.account_id}"
  }
}

resource "aws_kms_key" "cloudtrail-kms" {
  provider = aws.master
  description = "CloudTrail KMS Key"
  policy = data.template_file.cloudtrail-kms.rendered
}

data "template_file" "cloudtrail-kms" {
  template = file("${path.module}/policies/cloudtrail-kms.json")
  vars = {
    aws_account_id = data.aws_caller_identity.master.account_id
  }
}
