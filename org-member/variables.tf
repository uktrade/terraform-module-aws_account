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

# tflint-ignore: terraform_unused_declarations
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