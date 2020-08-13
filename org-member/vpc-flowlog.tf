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

resource "aws_iam_role" "vpc_log" {
  provider = aws.member
  name = "vpc_log"
  assume_role_policy = file("${path.module}/policies/vpc-flowlog-sts.json")
}

data "template_file" "vpc_log_policy" {
  template = file("${path.module}/policies/vpc-flowlog-role.json")
  vars = {
    flowlog_s3_buckets = jsonencode(tolist(aws_s3_bucket.vpc_log.*.arn))
  }
}

resource "aws_iam_role_policy" "vpc_log_policy" {
  provider = aws.member
  name = "vpc_log_policy"
  role = aws_iam_role.vpc_log.id
  policy = data.template_file.vpc_log_policy.rendered
}
