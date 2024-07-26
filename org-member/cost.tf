resource "aws_iam_policy" "cost_optimisation" {
  provider           = aws.member
  name               = "dit-cost-optimisation"
  description        = "Role used by AWS provides the permissions necessary for a member account to have full access to Cost Optimization Hub."
  policy = file("${path.module}/policies/org-policy-cost-member.json")
}