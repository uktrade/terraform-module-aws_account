resource "aws_config_configuration_aggregator" "master" {
  provider = "aws.master"
  name = "aws-org-config"
  organization_aggregation_source {
    all_regions = true
    role_arn = "${aws_iam_role.config_organization.arn}"
  }

  depends_on = ["aws_iam_role_policy_attachment.config_organization"]
}

resource "aws_iam_role" "config_organization" {
  provider = "aws.master"
  name = "config-organization"
  assume_role_policy = "${file("${path.module}/policies/config-sts.json")}"
}

resource "aws_iam_role_policy_attachment" "config_organization" {
  provider = "aws.master"
  role = "${aws_iam_role.config_organization.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_recorder" "master_config" {
  provider = "aws.master"
  name = "config-${data.aws_caller_identity.master.account_id}"
  role_arn = "${aws_iam_role.master_config_role.arn}"
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "master_config_role" {
  provider = "aws.master"
  name = "config-role"
  assume_role_policy = "${file("${path.module}/policies/config-sts.json")}"
}

resource "aws_iam_role_policy_attachment" "master_config_policy" {
  provider = "aws.master"
  role = "${aws_iam_role.master_config_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_s3_bucket" "master_config_bucket" {
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
  name = "config_s3_policy"
  role = "${aws_iam_role.master_config_role.id}"
  policy = "${data.template_file.config_s3_policy.rendered}"
}

resource "aws_config_configuration_recorder_status" "master_config" {
  provider = "aws.master"
  name = "${aws_config_configuration_recorder.master_config.name}"
  is_enabled = true
}

resource "aws_config_delivery_channel" "master" {
  provider = "aws.master"
  name = "aws-config-${data.aws_caller_identity.master.account_id}"
  s3_bucket_name = "${aws_s3_bucket.master_config_bucket.id}"
  sns_topic_arn = "${aws_sns_topic.config_sns.arn}"
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
}

resource "aws_sns_topic" "config_sns" {
  provider = "aws.master"
  name = "org-config-sns"
}

resource "aws_sns_topic_policy" "config_sns" {
  arn = "${aws_sns_topic.config_sns.arn}"
  policy = "${data.template_file.config_sns_policy.rendered}"
}

data "template_file" "config_sns_policy" {
  template = "${file("${path.module}/policies/config-sns-role.json")}"
  vars {
    config_sns_role = "${aws_iam_service_linked_role.config_sns_role.arn}"
    config_sns_arn = "${aws_sns_topic.config_sns.arn}"
  }
}

resource "aws_iam_service_linked_role" "config_sns_role" {
  provider = "aws.master"
  aws_service_name = "config.amazonaws.com"
}

resource "aws_iam_role_policy_attachment" "config_sns_policy" {
  provider = "aws.master"
  role = "${aws_iam_service_linked_role.config_sns_role.name}"
  policy_arn = "${aws_iam_policy.config_sns_policy.arn}"
}

resource "aws_iam_policy" "config_sns_policy" {
  provider = "aws.master"
  name = "aws-config-${data.aws_caller_identity.master.account_id}"
  policy = "${data.template_file.config_sns_role_policy.rendered}"
}

data "template_file" "config_sns_role_policy" {
  template = "${file("${path.module}/policies/config-sns.json")}"
  vars {
    config_role_arn = "${aws_iam_role.master_config_role.arn}"
  }
}
