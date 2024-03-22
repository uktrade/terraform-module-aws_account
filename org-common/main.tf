# tflint-ignore: terraform_unused_declarations
data "aws_region" "common" {
  provider = aws.common
}

data "aws_caller_identity" "common" {
  provider = aws.common
}
