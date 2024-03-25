data "aws_region" "master" {
  provider = aws.master
}

data "aws_region" "all_regions" {
  provider = aws.master
}

data "aws_caller_identity" "master" {
  provider = aws.master
}