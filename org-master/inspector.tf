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

# AWS Inspector V2

resource "aws_inspector2_delegated_admin_account" "master" {
  provider = aws.master
  account_id = data.aws_caller_identity.master.account_id
}

resource "aws_inspector2_enabler" "master" {
  provider = aws.master
  account_ids = [data.aws_caller_identity.master.account_id]
  resource_types = ["ECR", "EC2", "LAMBDA"]
  depends_on = [aws_inspector2_delegated_admin_account.master]
}

resource "aws_inspector2_organization_configuration" "master" {
  provider = aws.master
  auto_enable {
    ec2 = true
    ecr = true
    lambda = true
  }
  depends_on = [aws_inspector2_enabler.master]
}
