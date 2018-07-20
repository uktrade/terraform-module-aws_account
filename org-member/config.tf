resource "aws_config_configuration_recorder" "config" {
  provider = "aws.member.config"
  name = "config-${data.aws_caller_identity.member.account_id}"
  role_arn = "${aws_iam_role.config_role.arn}"
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config_role" {
  provider = "aws.member"
  name = "config-role"
  assume_role_policy = "${file("${path.module}/policies/config-sts.json")}"
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  provider = "aws.member"
  role = "${aws_iam_role.config_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_policy" "config_service_policy" {
  provider = "aws.member"
  name = "config_service_policy"
  policy = "${file("${path.module}/policies/config-svc.json")}"
}

resource "aws_iam_role_policy_attachment" "config_service_policy" {
  provider = "aws.member"
  role = "${aws_iam_role.config_role.id}"
  policy_arn = "${aws_iam_policy.config_service_policy.id}"
}

resource "aws_s3_bucket" "config_bucket" {
  provider = "aws.member"
  bucket = "aws-config-${data.aws_caller_identity.member.account_id}"
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
    config_s3_arn = "${aws_s3_bucket.config_bucket.arn}"
  }
}

resource "aws_iam_role_policy" "config_s3_policy" {
  provider = "aws.member"
  name = "config_s3_policy"
  role = "${aws_iam_role.config_role.id}"
  policy = "${data.template_file.config_s3_policy.rendered}"
}

resource "aws_config_configuration_recorder_status" "config" {
  provider = "aws.member.config"
  name = "${aws_config_configuration_recorder.config.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.member"]
}

resource "aws_config_aggregate_authorization" "member" {
  provider = "aws.master.config"
  account_id = "${data.aws_caller_identity.member.account_id}"
  region = "${data.aws_region.master_config.name}"
}

resource "aws_config_delivery_channel" "member" {
  provider = "aws.member.config"
  name = "aws-config-${data.aws_caller_identity.member.account_id}"
  s3_bucket_name = "${aws_s3_bucket.config_bucket.id}"
  sns_topic_arn = "${var.org["config_sns_arn"]}"
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
}

resource "aws_iam_role" "master_config_sts" {
  provider = "aws.master"
  name = "${var.org["config_role_name"]}"
  assume_role_policy = "${data.aws_iam_policy_document.master_config_sts.json}"
}

data "aws_iam_policy_document" "master_config_sts" {
  provider = "aws.master"
  source_json = "${data.aws_iam_role.master_config_role.assume_role_policy}"
  statement {
    sid = "OrgAccoount${data.aws_caller_identity.member.account_id}"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_role.config_role.arn}"]
    }
  }
}

data "aws_iam_role" "master_config_role" {
  provider = "aws.master"
  name = "${var.org["config_role_name"]}"
}
