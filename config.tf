resource "aws_config_configuration_aggregator" "master" {
  provider = "aws.master"
  name = "aws-org-config"
  organization_aggregation_source {
    all_regions = true
    role_arn = "${aws_iam_role.config_role.arn}"
  }
}

resource "aws_config_aggregate_authorization" "member" {
  provider = "aws.member"
  count = "${length(var.aws_regions)}"
  account_id = "${data.aws_caller_identity.member.account_id}"
  region = "${element(var.aws_regions, count.index)}"
}

resource "aws_config_configuration_recorder" "config" {
  provider = "aws.member"
  name = "config-${data.aws_caller_identity.member.account_id}"
  role_arn = "${aws_iam_role.config_role.arn}"
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

resource "aws_config_configuration_recorder_status" "config" {
  provider = "aws.member"
  name = "${aws_config_configuration_recorder.config.name}"
  is_enabled = true
}
