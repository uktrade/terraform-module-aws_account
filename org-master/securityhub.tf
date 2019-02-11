resource "aws_securityhub_account" "master" {
  provider = "aws.master"
}

resource "aws_securityhub_standards_subscription" "master" {
  provider = "aws.master"
  depends_on = ["aws_securityhub_account.master"]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}

resource "aws_securityhub_product_subscription" "securityhub-guardduty" {
  provider = "aws.master"
  depends_on = ["aws_securityhub_account.master"]
  product_arn = "arn:aws:securityhub:${data.aws_region.master.name}::product/aws/guardduty"
}

resource "aws_securityhub_product_subscription" "securityhub-inspector" {
  provider = "aws.master"
  depends_on = ["aws_securityhub_account.master"]
  product_arn = "arn:aws:securityhub:${data.aws_region.master.name}::product/aws/inspector"
}

resource "aws_securityhub_product_subscription" "securityhub-macie" {
  provider = "aws.master"
  depends_on = ["aws_securityhub_account.master"]
  product_arn = "arn:aws:securityhub:${data.aws_region.master.name}::product/aws/macie"
}
