# Setup SecurityHub on AWS Org account
resource "aws_securityhub_account" "master" {
  provider = aws.master
}

resource "aws_securityhub_standards_subscription" "master-cis" {
  provider = aws.master
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on = [aws_securityhub_account.master]
}

resource "aws_securityhub_standards_subscription" "master-aws" {
  provider = aws.master
  standards_arn = "arn:aws:securityhub:${data.aws_region.master.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on = [aws_securityhub_account.master]
}

resource "aws_securityhub_standards_subscription" "master-pci" {
  provider = aws.master
  standards_arn = "arn:aws:securityhub:${data.aws_region.master.name}::standards/pci-dss/v/3.2.1"
  depends_on = [aws_securityhub_account.master]
}
