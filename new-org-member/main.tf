variable "org" {
  type    = map(string)
  default = {}
}

variable "member" {
  type    = any
  default = {}
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.master]
    }
  }
}

data "aws_region" "master" {
  provider = aws.master
}

data "aws_caller_identity" "master" {
  provider = aws.master
}

variable "aws_regions" {
  type = list(string)
  default = [
    "ap-south-1",
    "eu-west-3",
    "eu-west-2",
    "eu-west-1",
    "ap-northeast-2",
    "ap-northeast-1",
    "sa-east-1",
    "ca-central-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "eu-central-1",
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2"
  ]
}
