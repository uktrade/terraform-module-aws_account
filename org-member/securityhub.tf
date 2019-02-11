resource "aws_securityhub_account" "member" {
  provider = "aws.member"
}

resource "aws_securityhub_product_subscription" "securityhub-guardduty" {
  provider = "aws.member"
  depends_on  = ["aws_securityhub_account.member"]
  product_arn = "arn:aws:securityhub:${data.aws_region.member.name}::product/aws/guardduty"
}

resource "aws_securityhub_product_subscription" "securityhub-inspector" {
  provider = "aws.member"
  depends_on  = ["aws_securityhub_account.member"]
  product_arn = "arn:aws:securityhub:${data.aws_region.member.name}::product/aws/inspector"
}

resource "aws_securityhub_product_subscription" "securityhub-macie" {
  provider = "aws.member"
  depends_on  = ["aws_securityhub_account.member"]
  product_arn = "arn:aws:securityhub:${data.aws_region.member.name}::product/aws/macie"
}
