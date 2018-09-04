resource "aws_iam_policy" "default_policy" {
  provider = "aws.master"
  name = "dit-default"
  policy = "${file("${path.module}/policies/default-policy.json")}"
}
