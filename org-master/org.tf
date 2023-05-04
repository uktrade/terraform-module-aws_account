# Setup Org default settings on AWS Org account
resource "aws_organizations_organization" "org" {
  provider = aws.master
  feature_set = "ALL"
  aws_service_access_principals = [
    "aws-artifact-account-sync.amazonaws.com",
    "ram.amazonaws.com",
    "license-manager.amazonaws.com",
    "servicecatalog.amazonaws.com",
    "ds.amazonaws.com",
    "fms.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "backup.amazonaws.com",
    "controltower.amazonaws.com"
  ]
  enabled_policy_types = [
    "BACKUP_POLICY",
    "SERVICE_CONTROL_POLICY"
  ]
}

resource "aws_organizations_policy" "org_policy" {
  provider = aws.master
  name = "default-pollicy"
  content = file("${path.module}/policies/org-policy.json")
}

resource "aws_organizations_policy" "backup_daily8_weekly5_monthly14" {
  provider = aws.master
  name = "daily8-weekly5-monthly14"
  description = "Daily (weekdays), retained for 8 days. Weekly (Saturday), retained for 5 weeks (35 days). Monthly (1st), retained for 14 months (420 days)."
  type = "BACKUP_POLICY"
  content = templatefile("${path.module}/policies/org-policy-backup-dwm.json",
    {
      aws_account_id = data.aws_caller_identity.master.account_id
      aws_region = data.aws_region.master.name
      iam_role = aws_iam_role.dit_backup.name
      backup_policy_label = "daily8-weekly5-monthly14"
      daily_job_cron = "15 22 ? * 2,3,4,5,6 *"
      daily_job_retention_days = 8
      weekly_job_cron = "25 22 ? * 7 *"
      weekly_job_retention_days = 35
      monthly_job_cron = "35 22 1 * ? *"    
      monthly_job_retention_days = 420
      monthly_job_cold_storage_days = 5
    }
  )
  tags = {
      "backup-policy-type" = "dit-central-backup"
      "backup-policy-name" = "daily8-weekly5-monthly14"
  }
}
