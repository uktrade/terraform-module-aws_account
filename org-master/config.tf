resource "aws_config_configuration_aggregator" "master" {
  provider = "aws.master.config"
  name = "aws-org-config"
  organization_aggregation_source {
    all_regions = true
    role_arn = "${aws_iam_role.master_config_role.arn}"
  }
  depends_on = ["aws_iam_role_policy_attachment.config_organization"]
}

resource "aws_iam_role" "master_config_role" {
  provider = "aws.master"
  name = "config-role"
  assume_role_policy = "${data.aws_iam_policy_document.master_config_sts.json}"
}

data "aws_iam_policy_document" "master_config_sts" {
  statement {
    sid = "DefaultPolicyForAWSConfig"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config_organization" {
  provider = "aws.master"
  role = "${aws_iam_role.master_config_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_recorder" "master_config" {
  provider = "aws.master.config"
  name = "config-${data.aws_caller_identity.master.account_id}"
  role_arn = "${aws_iam_role.master_config_role.arn}"
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role_policy_attachment" "master_config_policy" {
  provider = "aws.master"
  role = "${aws_iam_role.master_config_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_policy" "master_config_service_policy" {
  provider = "aws.master"
  name = "master_config_service_policy"
  policy = "${file("${path.module}/policies/config-svc.json")}"
}

resource "aws_iam_role_policy_attachment" "master_config_service_policy" {
  provider = "aws.master"
  role = "${aws_iam_role.master_config_role.name}"
  policy_arn = "${aws_iam_policy.master_config_service_policy.id}"
}

resource "aws_s3_bucket" "master_config_bucket" {
  provider = "aws.master"
  bucket = "aws-config-${data.aws_caller_identity.master.account_id}"
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "template_file" "config_s3_policy" {
  template = "${file("${path.module}/policies/config-s3.json")}"
  vars {
    config_s3_arn = "${aws_s3_bucket.master_config_bucket.arn}"
  }
}

resource "aws_iam_role_policy" "config_s3_policy" {
  provider = "aws.master"
  name = "config_s3_policy"
  role = "${aws_iam_role.master_config_role.id}"
  policy = "${data.template_file.config_s3_policy.rendered}"
}

resource "aws_config_configuration_recorder_status" "master_config" {
  provider = "aws.master.config"
  name = "${aws_config_configuration_recorder.master_config.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.master"]
}

resource "aws_config_delivery_channel" "master" {
  provider = "aws.master.config"
  name = "aws-config-${data.aws_caller_identity.master.account_id}"
  s3_bucket_name = "${aws_s3_bucket.master_config_bucket.id}"
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
  depends_on = ["aws_config_configuration_recorder.master_config"]
}

resource "aws_sns_topic" "config_sns" {
  provider = "aws.master.config"
  name = "org-config-sns"
}

resource "aws_iam_role_policy" "config_sns_policy" {
  provider = "aws.master"
  name = "config_sns_policy"
  role = "${aws_iam_role.master_config_role.id}"
  policy = "${data.aws_iam_policy_document.config_sns.json}"
}

data "aws_iam_policy_document" "config_sns" {
  provider = "aws.master"
  statement {
    sid = "DefaultPolicyForAWSConfig"
    actions = ["SNS:Publish"]
    resources = ["${aws_sns_topic.config_sns.arn}"]
  }
}
