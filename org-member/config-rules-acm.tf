resource "aws_config_config_rule" "config_rule_acm_expiration_acm" {
  provider = "aws.member.config_acm"
  name = "acm-certificate-expiration-check"
  source {
    owner = "AWS"
    source_identifier = "ACM_CERTIFICATE_EXPIRATION_CHECK"
  }
  input_parameters = <<INPUT
{
  "daysToExpiration": "14"
}
INPUT
  maximum_execution_frequency = "TwentyFour_Hours"
}
