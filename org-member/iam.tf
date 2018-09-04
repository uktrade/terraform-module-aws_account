resource "aws_iam_policy" "default_policy" {
  name = "dit-default"
  policy = "${file("${path.module}/policies/default-policy.json")}"
}
