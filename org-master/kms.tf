# Sentinel

resource "aws_kms_key" "sentinel_guard_duty" {
  provider              = aws.master
  description           = "Sentinel GuardDuty KMS Key"
  enable_key_rotation   = false
  policy = templatefile("${path.module}/policies/guardduty-kms.json",
    {
      master_account_id = data.aws_caller_identity.master.account_id
      sentinel_role_arn = aws_iam_role.sentinel_role.arn
    }
  )
  tags = tomap(local.sentinel_common_resource_tag)
}

resource "aws_kms_alias" "sentinel_guard_duty" {
  provider      = aws.master
  name          = "alias/sentinel-guardduty-key"
  target_key_id = aws_kms_key.sentinel_guard_duty.key_id
}

# Control Tower

resource "aws_kms_key" "control_tower" {
  provider              = aws.master
  description           = "KMS key for Control Tower"
  enable_key_rotation   = false
}

resource "aws_kms_key_policy" "control_tower" {
  provider = aws.master
  key_id   = aws_kms_key.control_tower.id
  policy = templatefile("${path.module}/policies/control-tower-kms.json",
    {
      account_id  = data.aws_caller_identity.master.account_id
      kms_key_arn = aws_kms_key.control_tower.arn
    }
  )
}

resource "aws_kms_alias" "control_tower" {
  provider      = aws.master
  name          = "alias/control-tower"
  target_key_id = aws_kms_key.control_tower.key_id
}
