data "aws_inspector_rules_packages" "rules" {
  provider = "aws.member"
}

resource "aws_inspector_resource_group" "all" {
  provider = "aws.member"
  tags = {}
}

resource "aws_inspector_assessment_target" "default" {
  provider = "aws.member"
  name = "default-target"
  resource_group_arn = "${aws_inspector_resource_group.all.arn}"
}

resource "aws_inspector_assessment_template" "default" {
  provider = "aws.member"
  name = "default-template"
  target_arn = "${aws_inspector_assessment_target.default.arn}"
  duration = 3600
  rules_package_arns = "${data.aws_inspector_rules_packages.rules.arns}"
}
