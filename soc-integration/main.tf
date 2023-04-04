variable "config" {
  type    = map(string)
  default = {}
}

variable "member" {
  type = map(string)
  default = {}
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [ aws.member ]
    }
  }
}
