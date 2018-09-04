resource "aws_iam_policy" "default_policy" {
  provider = "aws.member"
  name = "dit-default"
  policy = "${file("${path.module}/policies/default-policy.json")}"
}

resource "aws_iam_policy" "default_admin" {
  provider = "aws.member"
  name = "dit-default-admin"
  policy = "${data.aws_iam_policy_document.default_admin.json}"
}

data "aws_iam_policy_document" "default_admin" {
  provider = "aws.member"
  statement {
    sid = "EnableIAMforAdmin"
    actions = ["iam:*"]
    resources = ["*"]
    condition {
      test = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = ["${aws_iam_policy.default_policy.arn}"]
    }
  }
}
