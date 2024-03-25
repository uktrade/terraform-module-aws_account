data "aws_region" "common" {
  provider = aws.common
}

data "aws_caller_identity" "common" {
  provider = aws.common
}
