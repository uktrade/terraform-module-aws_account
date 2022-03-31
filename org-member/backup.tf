data "aws_kms_key" "aws_backup" {
  provider = aws.member
  key_id = "alias/aws/backup"
}

resource "aws_backup_vault" "daily8_weekly5_monthly14" {
  provider = aws.member
  name = "daily8-weekly5-monthly14"
  kms_key_arn = data.aws_kms_key.aws_backup.arn
}

resource "aws_organizations_policy_attachment" "backup_daily8_weekly5_monthly14" {
  provider = aws.master
  policy_id = var.org["organization_policy_backup_d8w5m14"]
  target_id = data.aws_caller_identity.member.account_id
}
