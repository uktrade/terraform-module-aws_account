data "aws_kms_key" "aws_backup" {
  provider = aws.member
  key_id = "alias/aws/backup"
}

resource "aws_backup_vault" "daily8_weekly5_monthly14" {
  provider = aws.member
  name = "daily8-weekly5-monthly14"
  kms_key_arn = data.aws_kms_key.aws_backup.arn
}
