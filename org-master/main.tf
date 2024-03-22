data "aws_region" "master" {
  provider = aws.master
}

# tflint-ignore: terraform_unused_declarations
data "aws_region" "all_regions" {
  provider = aws.master
}

data "aws_caller_identity" "master" {
  provider = aws.master
}