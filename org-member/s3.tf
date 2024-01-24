resource "aws_s3_account_public_access_block" "member_s3_public_access" {
  provider = aws.member
  block_public_acls       = try (var.member.account_public_access_block.block_public_acls, true)
  block_public_policy     = try (var.member.account_public_access_block.block_public_policy, true)
  ignore_public_acls      = try (var.member.account_public_access_block.ignore_public_acls, true)
  restrict_public_buckets = try (var.member.account_public_access_block.restrict_public_buckets, true)
}
