data "null_data_source" "org_master" {
  inputs = {
    account_id = data.aws_caller_identity.master.account_id
    aws_shared_credentials_file = var.org["aws_shared_credentials_file"]
    aws_profile = var.org["aws_profile"]
    organization_arn = aws_organizations_organization.org.arn
    organization_id = aws_organizations_organization.org.id
    cloudtrail_arn = aws_cloudtrail.trail.arn
    cloudwatch_eventbus_arn = "arn:aws:events:${data.aws_region.master.name}:${data.aws_caller_identity.master.account_id}:event-bus/default"
    config_id = aws_config_configuration_recorder.master_config.id
    config_sns_arn = aws_sns_topic.config_sns.arn
    config_role_arn = aws_iam_role.master_config_role.arn
    config_role_name = aws_iam_role.master_config_role.name
    guardduty_id = aws_guardduty_detector.master.id
    bastion_account = var.org["bastion_account"]
  }
}

output "org_master" {
  value = tomap({
            "account_id" = data.aws_caller_identity.master.account_id
            "aws_shared_credentials_file" = var.org["aws_shared_credentials_file"],
            "aws_profile" = var.org["aws_profile"],
            "organization_arn" = aws_organizations_organization.org.arn,
            "organization_id" = aws_organizations_organization.org.id,
            "cloudtrail_arn" = aws_cloudtrail.trail.arn,
            "cloudwatch_eventbus_arn" = "arn:aws:events:${data.aws_region.master.name}:${data.aws_caller_identity.master.account_id}:event-bus/default",
            "config_id" = aws_config_configuration_recorder.master_config.id,
            "config_sns_arn" = aws_sns_topic.config_sns.arn,
            "config_role_arn" = aws_iam_role.master_config_role.arn,
            "config_role_name" = aws_iam_role.master_config_role.name,
            "guardduty_id"=  aws_guardduty_detector.master.id,
            "bastion_account" = var.org["bastion_account"]
          })
}
