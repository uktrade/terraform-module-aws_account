variable "org" {
  type = map(string)
}

variable "password_policy_minimum_password_length" {
  default = 8
}

variable "password_policy_require_lowercase_characters" {
  default = true
}

variable "password_policy_require_numbers" {
  default = true
}

variable "password_policy_require_uppercase_characters" {
  default = true
}
variable "password_policy_require_symbols" {
  default = true
}
variable "password_policy_allow_users_to_change_password" {
  default = true
}

variable "password_policy_password_reuse_prevention" {
  default = 0
}

variable "password_policy_max_password_age" {
  default = 0 
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
