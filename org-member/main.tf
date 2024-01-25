variable "org" {
  type = map(string)
  default = {
    "aws_shared_credentials_file" = "~/.aws/credentials"
    "aws_profile"                 = "default"
    "bastion_account"             = "0"
  }
}

variable "member" {
  type = any
  default = {
    "aws_shared_credentials_file" = "~/.aws/credentials"
    "aws_profile"                 = "default"
    "dev_access"                  = "false"
    "aws_config_service_role"     = "AWS_ConfigRole"
  }
}

variable "soc_config" {
  type    = map(string)
  default = {}
}

variable "dev_iam_policy" {}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.master, aws.member]
    }
  }
}

data "aws_region" "master" {
  provider = aws.master
}

data "aws_region" "member" {
  provider = aws.member
}

data "aws_region" "all_regions" {
  provider = aws.member
}

data "aws_caller_identity" "master" {
  provider = aws.master
}

data "aws_caller_identity" "member" {
  provider = aws.member
}

variable "aws_regions" {
  type = list(string)
  default = [
    "eu-north-1",
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
