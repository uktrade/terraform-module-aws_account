resource "aws_config_configuration_recorder" "config_alt" {
  provider = "aws.member.config"
  name = "config-${data.aws_caller_identity.member.account_id}"
  role_arn = "${aws_iam_role.config_role.arn}"
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "config_alt" {
  provider = "aws.member.config"
  name = "${aws_config_configuration_recorder.config_alt.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.member_alt"]
}

resource "aws_config_delivery_channel" "member_alt" {
  provider = "aws.member.config"
  name = "aws-config-${data.aws_caller_identity.member.account_id}"
  s3_bucket_name = "${aws_s3_bucket.config_bucket.id}"
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
}

resource "aws_config_aggregate_authorization" "member_alt" {
  provider = "aws.master.config"
  account_id = "${data.aws_caller_identity.member.account_id}"
  region = "${data.aws_region.master_config.name}"
}
