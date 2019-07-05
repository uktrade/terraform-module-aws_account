variable "org" {
  type = "map"
  default = {}
}

variable "member" {
  type = "map"
  default = {
    "aws_shared_credentials_file" = "~/.aws/credentials"
    "aws_profile" = "default"
    "dev_access" = "false"
  }
}

provider "aws" {
  alias = "master"
}

provider "aws" {
  alias = "master.config"
  shared_credentials_file = "${var.org["aws_shared_credentials_file"]}"
  profile = "${var.org["aws_profile"]}"
  region = "${var.org["aws_config_region"]}"
}

provider "aws" {
  alias = "master.config_acm"
  shared_credentials_file = "${var.org["aws_shared_credentials_file"]}"
  profile = "${var.org["aws_profile"]}"
  region = "us-east-1"
}

data "aws_caller_identity" "master_config" {
  provider = "aws.master.config"
}

data "aws_region" "master_config" {
  provider = "aws.master.config"
}

data "aws_region" "master_config_acm" {
  provider = "aws.master.config_acm"
}

provider "aws" {
  alias = "member"
}

provider "aws" {
  alias = "member.config"
  shared_credentials_file = "${var.member["aws_shared_credentials_file"]}"
  profile = "${var.member["aws_profile"]}"
  region = "${var.org["aws_config_region"]}"
}

provider "aws" {
  alias = "member.config_acm"
  shared_credentials_file = "${var.member["aws_shared_credentials_file"]}"
  profile = "${var.member["aws_profile"]}"
  region = "us-east-1"
}

data "aws_region" "member_config" {
  provider = "aws.member.config"
}

data "aws_region" "member_config_acm" {
  provider = "aws.member.config_acm"
}

data "aws_region" "master" {
  provider = "aws.master"
}

data "aws_region" "member" {
  provider = "aws.member"
}

data "aws_region" "all_regions" {
  provider = "aws.member"
}

data "aws_caller_identity" "master" {
  provider = "aws.master"
}

data "aws_caller_identity" "member" {
  provider = "aws.member"
}

variable "aws_regions" {
  type = "list"
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
