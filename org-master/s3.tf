resource "aws_s3_bucket" "sentinel_logs" {
  provider = aws.master
  bucket   = "${var.config["sentinel_s3_bucket_name"]}-${data.aws_caller_identity.master.account_id}"
  acl      = "private"
  tags     = tomap(local.sentinel_common_resource_tag)

  lifecycle_rule {
    id      = "sentinel_log_expiry"
    enabled = true
    expiration {
      days = local.sentinel_log_expiry_days
    }
  }

}

resource "aws_s3_bucket_policy" "sentinel_logs" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_logs.id
  policy   = data.aws_iam_policy_document.sentinel_logs.json
}

data "aws_iam_policy_document" "sentinel_logs" {
  provider = aws.master
  version = "2012-10-17"

  statement {
    sid = "Allow Sentinel role read access to S3 log bucket"
    actions = ["s3:Get*","s3:List*"]
    effect   = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
      type = "AWS"
      identifiers = [aws_iam_role.sentinel_role.arn]
    }
  }

  statement {
    sid = "Allow GuardDuty to use the getBucketLocation operation"
    actions = ["s3:GetBucketLocation"]
    effect = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
        type = "Service"
        identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "Allow GuardDuty to upload objects to the bucket"
    actions = ["s3:PutObject"]
    effect = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
        type = "Service"
        identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "Deny GuardDuty unencrypted object uploads."
    actions = ["s3:PutObject"]
    effect = "Deny"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
        type = "Service"
        identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values = ["aws:kms"]
    }
  }

  statement {
    sid = "Deny GuardDuty incorrect encryption header."
    actions = ["s3:PutObject"]
    effect = "Deny"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
        type = "Service"
        identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values = [aws_kms_key.sentinel_guard_duty.arn]
    }
  }

  statement {
    sid = "Deny non-HTTPS access."
    actions = ["s3:*"]
    effect = "Deny"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
        type = "Service"
        identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
  }
  
  statement {
    sid = "AWSLogDeliveryWrite"
    actions = ["s3:PutObject"]
    effect = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
        type = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid = "AWSLogDeliveryCheck"
    actions = ["s3:GetBucketAcl", "s3:ListBucket"]
    effect = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}"]
    principals {
        type = "Service"
        identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid = "AWSCloudTrailWrite"
    actions = ["s3:PutObject"]
    effect = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/${local.sentinel_cloudtrail_folder}/*"]
    principals {
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSCloudTrailAclCheck"
    actions = ["s3:GetBucketAcl"]
    effect = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

}

resource "aws_s3_bucket_notification" "sentinel_logs" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_logs.id

  queue {
    queue_arn     = aws_sqs_queue.sentinel_flowlog_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = aws_s3_bucket_object.sentinel_vpc_flow_log_folder.id
    filter_suffix = ".gz"
  }

  queue {
    queue_arn     = aws_sqs_queue.sentinel_guardduty_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = aws_s3_bucket_object.sentinel_guardduty_folder.id
    filter_suffix = ".gz"
  }

    queue {
    queue_arn     = aws_sqs_queue.sentinel_cloudtrail_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = aws_s3_bucket_object.sentinel_cloudtrail_folder.id
    filter_suffix = ".gz"
  }

}

resource "aws_s3_bucket_object" "sentinel_vpc_flow_log_folder" {
    bucket = aws_s3_bucket.sentinel_logs.id
    content_type = "application/x-directory"
    key = "${local.sentinel_vpc_flow_log_folder}/"
}

resource "aws_s3_bucket_object" "sentinel_guardduty_folder" {
    bucket = aws_s3_bucket.sentinel_logs.id
    content_type = "application/x-directory"
    key = "${local.sentinel_guardduty_folder}/"
}

resource "aws_s3_bucket_object" "sentinel_cloudtrail_folder" {
    bucket = aws_s3_bucket.sentinel_logs.id
    content_type = "application/x-directory"
    key = "${local.sentinel_cloudtrail_folder}/"
}
