variable "org" {
  type = any
}

variable "password_policy_minimum_password_length" {
    type = number
    default = 8
}

variable "password_policy_require_lowercase_characters" {
    type = bool
    default = true
}

variable "password_policy_require_numbers" {
    type = bool
    default = true
}

variable "password_policy_require_uppercase_characters" {
    type = bool
    default = true
}
variable "password_policy_require_symbols" {
    type = bool
    default = true
}

variable "password_policy_allow_users_to_change_password" {
    type = bool
    default = true
}

variable "password_policy_password_reuse_prevention" {
    type = number
    default = 24
}

variable "password_policy_max_password_age" {
    type = number
    default = 0
}