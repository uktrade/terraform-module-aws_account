

locals {
  lifecycle_policy = file("${path.module}/policies/ecr-policy.json")
}


data "aws_ecr_repositories" "ecr_repos" {
  provider = aws.member
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  for_each           = var.deploy_ecr_policy ? toset(data.aws_ecr_repositories.ecr_repos.names) : []
  provider           = aws.member
  repository         = each.value
  policy             = local.lifecycle_policy
}