resource "aws_organizations_policy" "org_cost_policy" {
  provider = aws.master
  name     = "cost-optimisation-policy"
  content  = file("${path.module}/policies/org-policy-cost-optimisation.json")
}