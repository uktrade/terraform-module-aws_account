# Setup VPC Flowlogs on AWS Org member account
data "aws_vpcs" "vpcs" {
  provider = aws.member
}

resource "aws_s3_bucket" "vpc_log" {
  provider = aws.member
  bucket = "flowlog-${data.aws_caller_identity.member.account_id}"
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

resource "aws_flow_log" "vpc_log" {
  provider = aws.member
  for_each = toset(data.aws_vpcs.vpcs.ids)
  log_destination_type = "s3"
  log_destination = "${aws_s3_bucket.vpc_log.arn}/${each.key}"
  vpc_id = each.key
  traffic_type = "ALL"
}

resource "aws_flow_log" "sentinel_vpc_log" {
  provider = aws.member
  for_each = toset(data.aws_vpcs.vpcs.ids)
  log_destination_type = "s3"
  log_destination = var.org["sentinel_vpc_s3_bucket"]
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
