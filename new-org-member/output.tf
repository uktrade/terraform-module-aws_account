output "org_master" {
  value = tomap({
    "account_id"    = aws_organizations_account.member.id,
    "account_arn"   = aws_organizations_account.member.arn,
    "account_email" = var.member["email"],
    "account_alias" = var.member["name"]
  })
}
