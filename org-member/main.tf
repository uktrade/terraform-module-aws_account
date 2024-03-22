data "aws_region" "master" {
  provider = aws.master
}

data "aws_region" "member" {
  provider = aws.member
}

# tflint-ignore: terraform_unused_declarations
data "aws_region" "all_regions" {
  provider = aws.member
}

data "aws_caller_identity" "master" {
  provider = aws.master
}

data "aws_caller_identity" "member" {
  provider = aws.member
}

data "aws_caller_identity" "logarchive" {
  provider = aws.logarchive
}

