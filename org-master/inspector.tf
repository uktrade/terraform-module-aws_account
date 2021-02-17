# Setup Inspector on AWS Org account
data "aws_inspector_rules_packages" "rules" {
  provider = aws.master
}

resource "aws_inspector_assessment_target" "default" {
  provider = aws.master
  name = "default-target"
}

resource "aws_inspector_assessment_template" "default" {
  provider = aws.master
  name = "default-template"
  target_arn = aws_inspector_assessment_target.default.arn
  duration = 3600
  rules_package_arns = tolist(data.aws_inspector_rules_packages.rules.arns)
}
