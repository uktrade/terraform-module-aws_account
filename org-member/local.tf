# Sentinel Local Values
locals {
  sentinel_common_resource_tag_name = "Operator"
  sentinel_common_resource_tag_value = "Microsoft_Sentinel_Automation_Script"
  sentinel_common_resource_tag = {"${local.sentinel_common_resource_tag_name}" = "${local.sentinel_common_resource_tag_value}"}
  aws_organization_id = element(split("/", var.org["organization_arn"]), 1)
}
