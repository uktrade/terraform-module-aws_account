output "org_master" {
  value = tomap({
            "account_id" = data.aws_caller_identity.master.account_id
            "aws_shared_credentials_file" = var.org["aws_shared_credentials_file"],
            "aws_profile" = var.org["aws_profile"],
            "organization_arn" = aws_organizations_organization.org.arn,
            "organization_policy_backup_d8w5m14" = aws_organizations_policy.backup_daily8_weekly5_monthly14.id,
            "backup_to_slack_lambda_arn" = aws_lambda_function.aws_backup_to_slack.arn
            "cloudtrail_arn" = aws_cloudtrail.trail.arn,
            "cloudwatch_eventbus_arn" = "arn:aws:events:${data.aws_region.master.name}:${data.aws_caller_identity.master.account_id}:event-bus/default",
            "guardduty_id"=  aws_guardduty_detector.master.id,
            "sentinel_vpc_s3_bucket" = "${aws_s3_bucket.sentinel_logs.arn}/${local.sentinel_vpc_flow_log_folder}",
            "bastion_account" = var.org["bastion_account"]
          })
}
