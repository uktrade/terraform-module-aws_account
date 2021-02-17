# Add account to AWS Organization
resource "aws_organizations_account" "member" {
  provider = aws.master
  name  = var.member["name"]
  email = var.member["email"]
  iam_user_access_to_billing = "ALLOW"
}
