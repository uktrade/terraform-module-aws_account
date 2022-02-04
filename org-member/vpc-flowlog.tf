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
  count = length(data.aws_vpcs.vpcs.ids)
  log_destination_type = "s3"
  log_destination = "${aws_s3_bucket.vpc_log.arn}/${tolist(data.aws_vpcs.vpcs.ids)[count.index]}"
  vpc_id = tolist(data.aws_vpcs.vpcs.ids)[count.index]
  traffic_type = "ALL"
}

resource "aws_flow_log" "sentinel_vpc_log" {
  provider = aws.member
  for_each = data.aws_vpcs.vpcs.ids
  log_destination_type = "s3"
  log_destination = var.org["sentinel_vpc_s3_bucket"]
  vpc_id = each.key
  traffic_type = "ALL"
  tags = merge(
    tomap(local.sentinel_common_resource_tag),
    {
      "Name" = "sentinel-vpc-log"
    }
  )
}
