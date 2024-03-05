
resource "aws_servicequotas_service_quota" "sq-elastic-ips" {
  provider     = aws.member
  quota_code   = "L-0263D0A3"
  service_code = "ec2"
  value        = try(var.member.service_quotas.elastic-ips, 5)
}
resource "aws_servicequotas_service_quota" "sq-natgws-per-az" {
  provider     = aws.member
  quota_code   = "L-FE5A380F"
  service_code = "vpc"
  value        = try(var.member.service_quotas.natgws-per-az, 5)
}
resource "aws_servicequotas_service_quota" "sq-vpcs-per-region" {
  provider     = aws.member
  quota_code   = "L-F678F1CE"
  service_code = "vpc"
  value        = try(var.member.service_quotas.vpcs-per-region, 5)
}

