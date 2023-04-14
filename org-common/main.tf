variable "org" {
  type = map(string)
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [ aws.common ]
    }
  }
}

data "aws_region" "common" {
  provider = aws.common
}

data "aws_caller_identity" "common" {
  provider = aws.common
}
