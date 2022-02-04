resource "aws_kms_key" "sentinel_guard_duty" {
  description = "Sentinel GuardDuty KMS Key"
  policy = templatefile("${path.module}/policies/guardduty-kms.json",
    {
      master_account_id = data.aws_caller_identity.master.account_id
      sentinel_role_arn = aws_iam_role.sentinel_role.arn
    }
  )
  tags = tomap(local.sentinel_common_resource_tag)
}

resource "aws_kms_alias" "sentinel_guard_duty" {
  name = "alias/sentinel-guardduty-key"
  target_key_id = aws_kms_key.sentinel_guard_duty.key_id
}

