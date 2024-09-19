# Add account to AWS Organization and assign to an OU
data "aws_organizations_organization" "org" {
  provider = aws.master
}

data "aws_organizations_organizational_unit" "ou" {
  provider = aws.master
  parent_id = data.aws_organizations_organization.org.roots[0].id
  name      = var.member["org_ou"]
}

resource "aws_organizations_account" "member" {
  provider                   = aws.master
  name                       = var.member["name"]
  email                      = var.member["email"]
  iam_user_access_to_billing = "ALLOW"
  # parent_id = data.aws_organizations_organizational_unit.ou.id
}
