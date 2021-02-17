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
    "sso.amazonaws.com"
  ]
}

resource "aws_organizations_policy" "org_policy" {
  provider = aws.master
  name = "default-pollicy"
  content = file("${path.module}/policies/org-policy.json")
}
