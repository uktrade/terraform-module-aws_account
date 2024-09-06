terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.55"
      configuration_aliases = [aws.master, aws.member, aws.logarchive, aws.ci]
    }
  }
}
