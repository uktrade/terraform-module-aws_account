variable "account_alias" {
  type = string
}

variable "connect_aws_account" {
  type = bool
  default = true
}

variable "is_master" {
  type = bool
  default = false
}
