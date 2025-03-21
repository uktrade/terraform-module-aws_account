terraform {
  required_version = ">= 1.2.6"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.55"
      configuration_aliases = [aws.member]
    }
    datadog = {
      source = "DataDog/datadog"
    }
  }
}
