# Setup SecurityHub on AWS Org member account
resource "aws_securityhub_account" "member" {
  provider = aws.member
}

resource "aws_securityhub_standards_subscription" "member-cis" {
  provider = aws.member
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on = [aws_securityhub_account.member]
}

resource "aws_securityhub_standards_subscription" "member-aws" {
  provider = aws.member
  standards_arn = "arn:aws:securityhub:${data.aws_region.master.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on = [aws_securityhub_account.member]
}

resource "aws_securityhub_standards_subscription" "member-pci" {
  provider = aws.member
  standards_arn = "arn:aws:securityhub:${data.aws_region.master.name}::standards/pci-dss/v/3.2.1"
  depends_on = [aws_securityhub_account.member]
}
