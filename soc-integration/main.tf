variable "config" {
  type    = map(string)
  default = {}
}

provider "aws" {
  alias = "member"
}
