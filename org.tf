resource "aws_organizations_organization" "org" {
  provider = "aws.master"
  feature_set = "ALL"
}

resource "aws_organizations_policy" "org_policy" {
  provider = "aws.master"
  name = "default-pollicy"
  content = "${file("${path.module}/policies/org-policy.json")}"
}

resource "aws_organizations_policy_attachment" "root_polilcy" {
  provider = "aws.master"
  policy_id = "${aws_organizations_policy.org_policy.id}"
  target_id = "${data.aws_caller_identity.master.account_id}"
}

resource "aws_organizations_policy_attachment" "account_polilcy" {
  provider = "aws.master"
  policy_id = "${aws_organizations_policy.org_policy.id}"
  target_id = "${data.aws_caller_identity.member.account_id}"
}
