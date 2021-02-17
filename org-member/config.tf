# Setup Config on AWS Org member account
resource "aws_iam_role" "config_role" {
  provider = aws.member
  name = "config-role"
  assume_role_policy = file("${path.module}/policies/config-sts.json")
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  provider = aws.member
  role = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_policy" "config_service_policy" {
  provider = aws.member
  name = "config_service_policy"
  policy = file("${path.module}/policies/config-svc.json")
}

resource "aws_iam_role_policy_attachment" "config_service_policy" {
  provider = aws.member
  role = aws_iam_role.config_role.name
  policy_arn = aws_iam_policy.config_service_policy.id
}

resource "aws_s3_bucket" "config_bucket" {
  provider = aws.member
  bucket = "aws-config-${data.aws_caller_identity.member.account_id}"
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
}

data "template_file" "config_s3_policy" {
  template = file("${path.module}/policies/config-s3.json")
  vars = {
    config_s3_arn = aws_s3_bucket.config_bucket.arn
  }
}

resource "aws_iam_role_policy" "config_s3_policy" {
  provider = aws.member
  name = "config_s3_policy"
  role = aws_iam_role.config_role.name
  policy = data.template_file.config_s3_policy.rendered
}

resource "aws_config_configuration_recorder" "config" {
  provider = aws.member
  name = "config-${data.aws_caller_identity.member.account_id}"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "config" {
  provider = aws.member
  name = aws_config_configuration_recorder.config.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.member]
}

resource "aws_config_aggregate_authorization" "member" {
  provider = aws.member
  account_id = data.aws_caller_identity.member.account_id
  region = data.aws_region.master.name
}

resource "aws_config_delivery_channel" "member" {
  provider = aws.member
  name = "aws-config-${data.aws_caller_identity.member.account_id}"
  s3_bucket_name = aws_s3_bucket.config_bucket.id
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
}

resource "aws_cloudwatch_event_target" "config" {
  provider = aws.member
  arn = "arn:aws:events:${data.aws_region.master.name}:${data.aws_caller_identity.master.account_id}:event-bus/default"
  rule = aws_cloudwatch_event_rule.config.name
  target_id = "org-config-${data.aws_caller_identity.member.account_id}"
}

resource "aws_cloudwatch_event_rule" "config" {
  provider = aws.member
  name = "rule-config-${data.aws_caller_identity.member.account_id}"
  event_pattern = <<INPUT
{
  "source": [
    "aws.config"
  ],
  "detail-type": [
    "Config Rules Compliance Change"
  ]
}
INPUT
}
