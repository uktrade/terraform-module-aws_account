data "null_data_source" "org_master" {
  inputs = {
    organization_arn = "${aws_organizations_organization.org.arn}"
    cloudtrail_arn = "${aws_cloudtrail.trail.arn}"
    config_id = "${aws_config_configuration_recorder.master_config.id}"
    config_sns_arn = "${aws_sns_topic.config_sns.arn}"
    config_sns_role_arn = "${aws_iam_service_linked_role.config_sns_role.arn}"
    config_sns_role_name = "${aws_iam_service_linked_role.config_sns_role.name}"
    guardduty_id = "${aws_guardduty_detector.master.id}"
  }
}

output "org_master" {
  value = "${map(
            "organization_arn", "${aws_organizations_organization.org.arn}",
            "cloudtrail_arn", "${aws_cloudtrail.trail.arn}",
            "config_id", "${aws_config_configuration_recorder.master_config.id}",
            "config_sns_arn", "${aws_sns_topic.config_sns.arn}",
            "config_sns_role_name", "${aws_iam_service_linked_role.config_sns_role.name}",
            "guardduty_id", "${aws_guardduty_detector.master.id}"
          )}"
}
