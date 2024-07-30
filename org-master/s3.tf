resource "aws_s3_account_public_access_block" "master_s3_public_access" {
  provider                = aws.master
  block_public_acls       = try(var.org.account_public_access_block.block_public_acls, true)
  block_public_policy     = try(var.org.account_public_access_block.block_public_policy, true)
  ignore_public_acls      = try(var.org.account_public_access_block.ignore_public_acls, true)
  restrict_public_buckets = try(var.org.account_public_access_block.restrict_public_buckets, true)
}

resource "aws_s3_bucket" "sentinel_logs" {
  provider = aws.master
  bucket   = "${var.soc_config["sentinel_s3_bucket_name"]}-${data.aws_caller_identity.master.account_id}"
  tags     = tomap(local.sentinel_common_resource_tag)
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sentinel_logs_sse" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sentinel_logs_lifecycle" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_logs.id
  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    id     = "sentinel_log_expiry"
    status = "Enabled"
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
  version  = "2012-10-17"

  statement {
    sid       = "Allow Sentinel role read access to S3 log bucket"
    actions   = ["s3:Get*", "s3:List*"]
    effect    = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sentinel_role.arn]
    }
  }

  statement {
    sid       = "Allow GuardDuty to use the getBucketLocation operation"
    actions   = ["s3:GetBucketLocation"]
    effect    = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid       = "Allow GuardDuty to upload objects to the bucket"
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid       = "Deny GuardDuty unencrypted object uploads."
    actions   = ["s3:PutObject"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid       = "Deny GuardDuty incorrect encryption header."
    actions   = ["s3:PutObject"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.sentinel_guard_duty.arn]
    }
  }

  statement {
    sid       = "Deny non-HTTPS access."
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid     = "AWSLogDeliveryCheck"
    actions = ["s3:GetBucketAcl", "s3:ListBucket"]
    effect  = "Allow"

    resources = ["${aws_s3_bucket.sentinel_logs.arn}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.sentinel_logs.arn}/${local.sentinel_cloudtrail_folder}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "AWSCloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    effect    = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailAclCheck20150319"
    actions   = ["s3:GetBucketAcl"]
    effect    = "Allow"
    resources = [aws_s3_bucket.sentinel_logs.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudtrail.sentinel-trail.arn]
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite20150319-Account"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    resources = [
      "${aws_s3_bucket.sentinel_logs.arn}/CloudTrail/AWSLogs/${data.aws_caller_identity.master.account_id}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudtrail.sentinel-trail.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite20150319-Organization"
    actions = ["s3:PutObject"]
    effect  = "Allow"
    resources = [
      "${aws_s3_bucket.sentinel_logs.arn}/CloudTrail/AWSLogs/${local.aws_organization_id}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudtrail.sentinel-trail.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

}

resource "aws_s3_bucket_notification" "sentinel_logs" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_logs.id

  queue {
    queue_arn     = aws_sqs_queue.sentinel_flowlog_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "${local.sentinel_vpc_flow_log_folder}/"
    filter_suffix = ".gz"
  }

  queue {
    queue_arn     = aws_sqs_queue.sentinel_guardduty_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "${local.sentinel_guardduty_folder}/"
    filter_suffix = ".gz"
  }

  queue {
    queue_arn     = aws_sqs_queue.sentinel_cloudtrail_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "${local.sentinel_cloudtrail_folder}/"
    filter_suffix = ".gz"
  }

}

/* new aws vpc bucket  */
locals {
  vpc_flowlog_tags = {
    "Terraform_source_repo" = "terraform-module-aws_account"
    "Service"               = "sentinel-vpc-flowlog"
    "Environment"           = var.deployment_environment
  }
}

resource "aws_s3_bucket" "sentinel_vpc_flowlog_bucket" {
  provider = aws.master
  bucket   = "sentinel-vpc-flowlog-${data.aws_caller_identity.master.account_id}"
  lifecycle {
    ignore_changes = [grant]
  }
  tags = local.vpc_flowlog_tags
}

resource "aws_s3_object" "empty_bucket_readme" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_vpc_flowlog_bucket.bucket
  key      = "_Empty Bucket? Do not delete! README.txt"
  source   = "${path.module}/files/empty-bucket-readme.txt"
  tags     = local.vpc_flowlog_tags
}

resource "aws_s3_bucket_ownership_controls" "sentinel_vpc_flowlog_bucket" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_vpc_flowlog_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "sentinel_vpc_flowlog_bucket_account_access" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_vpc_flowlog_bucket.id
  policy   = data.aws_iam_policy_document.sentinel_vpc_flowlog_bucket_account_access.json
}

data "aws_organizations_organization" "master" {
  provider = aws.master
}

data "aws_sqs_queue" "sqs_sentinel_s3_vpc_flowlog_incoming" {
  provider = aws.elk
  name     = "microsoft-sentinel-s3-vpc_flowlog"
}

data "aws_iam_role" "ecsTaskRole" {
  provider = aws.elk
  name     = "sentinel-vpc-flowlog-task-ecs"

}
data "aws_iam_policy_document" "sentinel_vpc_flowlog_bucket_account_access" {
  statement {
    sid = "acl-access-from-accounts-for-vpc_flowlog-logging"
    principals {
      type = "AWS"
      identifiers = [for id in data.aws_organizations_organization.master.non_master_accounts[*].id :
        "arn:aws:iam::${id}:root"
      ]
    }
    actions   = ["s3:GetBucketAcl", "s3:PutBucketAcl"]
    effect    = "Allow"
    resources = [aws_s3_bucket.sentinel_vpc_flowlog_bucket.arn]
  }
  statement {
    sid = "elk-ecs-access-to-get-and-delete-s3-objects"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.ecsTaskRole.arn]
    }

    actions   = ["s3:GetObject", "s3:DeleteObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.sentinel_vpc_flowlog_bucket.arn}/*"]
  }

  /* Ploicy to give write access from vpc flow log service to sentinel bucket */
  statement {
    sid = "service-write-access-from-accounts-for-vpc_flowlog-logging"

    actions = ["s3:PutObject"]

    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }


    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = data.aws_organizations_organization.master.non_master_accounts[*].id
    }

    resources = [aws_s3_bucket.sentinel_vpc_flowlog_bucket.arn, "${aws_s3_bucket.sentinel_vpc_flowlog_bucket.arn}/*"]
  }
  statement {
    sid = "service-acl-access-from-accounts-for-vpc_flowlog-logging"

    actions = ["s3:GetBucketAcl", "s3:ListBucket"]

    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = data.aws_organizations_organization.master.non_master_accounts[*].id
    }

    resources = [aws_s3_bucket.sentinel_vpc_flowlog_bucket.arn, "${aws_s3_bucket.sentinel_vpc_flowlog_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_notification" "sentinel_vpc_flowlog_bucket_notification" {
  provider = aws.master
  bucket   = aws_s3_bucket.sentinel_vpc_flowlog_bucket.id

  queue {
    id        = "${data.aws_sqs_queue.sqs_sentinel_s3_vpc_flowlog_incoming.name}-incoming"
    queue_arn = data.aws_sqs_queue.sqs_sentinel_s3_vpc_flowlog_incoming.arn
    events    = ["s3:ObjectCreated:*"]
  }
}