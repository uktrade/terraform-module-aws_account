data "aws_vpcs" "vpcs" {
  provider = aws.master
}

resource "aws_s3_bucket" "vpc_log" {
  provider = aws.master
  count = length(data.aws_vpcs.vpcs.ids)
  bucket = tolist(data.aws_vpcs.vpcs.ids)[count.index]
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
  provider = aws.master
  count = length(data.aws_vpcs.vpcs.ids)
  log_destination_type = "s3"
  log_destination = tolist(aws_s3_bucket.vpc_log.*.arn)[count.index]
  iam_role_arn = aws_iam_role.vpc_log.arn
  vpc_id = tolist(data.aws_vpcs.vpcs.ids)[count.index]
  traffic_type = "ALL"
}

resource "aws_iam_role" "vpc_log" {
  provider = aws.master
  name = "vpc_log"
  assume_role_policy = file("${path.module}/policies/vpc-flowlog-sts.json")
}

resource "aws_iam_role_policy" "vpc_log_policy" {
  provider = aws.master
  name = "vpc_log_policy"
  role = aws_iam_role.vpc_log.id
  policy = templatefile("${path.module}/policies/vpc-flowlog-role.json", { flowlog-s3-bucket = tolist(aws_s3_bucket.vpc_log.*.arn)[count.index] })
}
