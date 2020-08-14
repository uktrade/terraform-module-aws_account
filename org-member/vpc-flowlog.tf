data "aws_vpcs" "vpcs" {
  provider = aws.member
}

resource "aws_s3_bucket" "vpc_log" {
  provider = aws.member
  count = length(data.aws_vpcs.vpcs.ids)
  bucket = sort(tolist(data.aws_vpcs.vpcs.ids))[count.index]
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
  log_destination = sort(tolist(aws_s3_bucket.vpc_log.*.arn))[count.index]
  vpc_id = sort(tolist(data.aws_vpcs.vpcs.ids))[count.index]
  traffic_type = "ALL"
}
