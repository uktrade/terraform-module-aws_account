# resource "aws_iam_role" "cost_optimisation" {
#   provider           = aws.member
#   name               = "dit-cost-optimisation"
#   description        = "Role used by AWS provides the permissions necessary for a member account to have full access to Cost Optimization Hub."
#   assume_role_policy = file("${path.module}/policies/org-policy-cost-member.json")
# }