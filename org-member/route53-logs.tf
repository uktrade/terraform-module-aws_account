locals {
  tags = {
    managed-by = "DBT SRE - Terraform"
    Name       = "SRE-2189-Resolver-Logging"
  }
}

resource "aws_route53_resolver_query_log_config" "sentinel" {
  provider        = aws.member
  name            = "sentinel-query-logging"
  destination_arn = aws_kinesis_firehose_delivery_stream.sentinel_route53_query_logs.arn

  tags = local.tags
}

resource "aws_route53_resolver_query_log_config_association" "sentinel" {
  provider = aws.member
  for_each = toset(data.aws_vpcs.vpcs.ids)

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.sentinel.id
  resource_id                  = each.key
}

# For the final implementation, this will be a logstash instance 
resource "aws_kinesis_firehose_delivery_stream" "sentinel_route53_query_logs" {
  provider    = aws.member
  name        = "kinesis-firehose-logstash-sentinel-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.resolver_query_logs.arn
    buffering_size     = 15
    buffering_interval = 300
  }

  tags = local.tags
}


resource "aws_s3_bucket" "resolver_query_logs" {
  provider      = aws.member
  bucket_prefix = "resolver-query-logs-"
}

resource "aws_iam_role" "firehose_role" {
  provider = aws.member
  name     = "firehose_query_logs_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "firehose_role_policy" {
  provider = aws.member
  name     = "firehose_uel_role_policy"
  role     = aws_iam_role.firehose_role.id
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.resolver_query_logs.arn}",
        "${aws_s3_bucket.resolver_query_logs.arn}/*"
      ]
    }
  ]
}
EOF
}

