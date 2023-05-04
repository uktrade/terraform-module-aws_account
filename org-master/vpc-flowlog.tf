# Setup VPC Flowlogs on AWS Org account
data "aws_vpcs" "vpcs" {
  provider = aws.master
}

resource "aws_s3_bucket" "vpc_log" {
  provider = aws.master
  bucket = "flowlog-${data.aws_caller_identity.master.account_id}"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    enabled = true
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "vpc_log" {
  provider = aws.master
  bucket   = aws_s3_bucket.vpc_log.id
  policy   = data.aws_iam_policy_document.vpc_log.json
}

data "aws_iam_policy_document" "vpc_log" {
  provider = aws.master
  version = "2012-10-17"
  statement {
    sid = "Deny non-HTTPS access."
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.vpc_log.arn}",
      "${aws_s3_bucket.vpc_log.arn}/*"
    ]
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
  }
  statement {
    sid = "AWSLogDeliveryWrite"
    principals {
      type = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    effect = "Allow"
    resources = ["${aws_s3_bucket.vpc_log.arn}/*"]
    condition {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = ["bucket-owner-full-control"]
    }
    condition {
      test = "StringEquals"
      variable = "aws:SourceAccount"
      values = [data.aws_caller_identity.master.account_id]
    }
    condition {
      test = "ArnLike"
      variable = "aws:SourceArn"
      values = ["arn:aws:logs:${data.aws_region.master.name}:${data.aws_caller_identity.master.account_id}:*"]
    }
  }
  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    effect = "Allow"
    resources = [aws_s3_bucket.vpc_log.arn]
    condition {
      test = "StringEquals"
      variable = "aws:SourceAccount"
      values = [data.aws_caller_identity.master.account_id]
    }
    condition {
      test = "ArnLike"
      variable = "aws:SourceArn"
      values = ["arn:aws:logs:${data.aws_region.master.name}:${data.aws_caller_identity.master.account_id}:*"]
    }
  }
}

resource "aws_flow_log" "vpc_log" {
  provider = aws.master
  for_each = toset(data.aws_vpcs.vpcs.ids)
  log_destination_type = "s3"
  log_destination = "${aws_s3_bucket.vpc_log.arn}/${each.key}"
  vpc_id = each.key
  traffic_type = "ALL"
}

resource "aws_flow_log" "sentinel_vpc_log" {
  provider = aws.master
  for_each = toset(data.aws_vpcs.vpcs.ids)
  log_destination_type = "s3"
  log_destination = "${aws_s3_bucket.sentinel_logs.arn}/${local.sentinel_vpc_flow_log_folder}"
  log_format = var.soc_config["sentinel_vpc_log_format"]
  vpc_id = each.key
  traffic_type = "ALL"
  tags = merge(
    tomap(local.sentinel_common_resource_tag),
    {
      "Name" = "sentinel-vpc-log"
    }
  )
}
