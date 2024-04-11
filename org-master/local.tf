# Sentinel Local Values
locals {
  sentinel_common_resource_tag_name  = "Operator"
  sentinel_common_resource_tag_value = "Microsoft_Sentinel_Automation_Script"
  sentinel_common_resource_tag       = { "${local.sentinel_common_resource_tag_name}" = "${local.sentinel_common_resource_tag_value}" }
  sentinel_vpc_flow_log_folder       = "VPC-Flow-Log"
  sentinel_guardduty_folder          = "GuardDuty"
  sentinel_cloudtrail_folder         = "CloudTrail"
  sentinel_log_expiry_days           = 14
  aws_organization_id                = element(split("/", aws_organizations_organization.org.id), 1)
}
