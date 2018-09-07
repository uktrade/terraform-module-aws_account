resource "aws_iam_policy" "default_policy" {
  provider = "aws.member"
  name = "dit-default"
  policy = "${file("${path.module}/policies/default-boundary-policy.json")}"
}

resource "aws_iam_policy" "default_admin" {
  provider = "aws.member"
  name = "dit-default-admin"
  policy = "${data.aws_iam_policy_document.default_admin.json}"
}

data "aws_iam_policy_document" "default_admin" {
  provider = "aws.member"
  override_json = "${aws_iam_policy.default_policy.policy}"
  statement {
    sid = "EnableIAMforAdmin"
    actions = ["iam:*"]
    resources = ["*"]
  }
  statement {
    sid = "EnableServicesForUSRegion"
    actions = [
      "acm:*",
      "config:*"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      variable = "aws:RequestedRegion"
      values = ["us-east-1"]
    }
  }
}

resource "aws_iam_policy" "default_dev" {
  provider = "aws.member"
  name = "dit-default-dev"
  policy = "${data.aws_iam_policy_document.default_dev.json}"
}

data "aws_iam_policy_document" "default_dev" {
  provider = "aws.member"
  override_json = "${aws_iam_policy.default_policy.policy}"
  statement {
    sid = "EnableServicesForUSRegion"
    actions = [
      "acm:Describe*",
      "acm:Get*",
      "acm:List*",
      "config:Describe*",
      "config:Get*",
      "config:List*"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      variable = "aws:RequestedRegion"
      values = ["us-east-1"]
    }
  }
}

resource "aws_iam_group" "bastion_readonly" {
  provider = "aws.member"
  name = "readonly"
}

resource "aws_iam_group_policy" "bastion_readonly" {
  provider = "aws.member"
  name = "readonly-group"
  group = "${aws_iam_group.bastion_readonly.name}"
  policy = "${file("${path.module}/policies/default-policy.json")}"
}

resource "aws_iam_role" "bastion_readonly" {
  provider = "aws.member"
  name = "dit-readonly"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_sts_readonly.json}"
  max_session_duration = 43200
  permissions_boundary = "${aws_iam_policy.default_policy.arn}"
}

data "aws_iam_policy_document" "bastion_sts_readonly" {
  provider = "aws.member"
  statement {
    sid = "TrustBastionAccount"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.org["bastion_account"]}:root"]
    }
    condition {
      test = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = ["${var.org["organization_id"]}"]
    }
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["true"]
    }
    condition {
      test = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = ["arn:aws:iam::${var.org["bastion_account"]}:policy/dit-readonly"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_readonly" {
  provider = "aws.member"
  role = "${aws_iam_role.bastion_readonly.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_group" "bastion_admin" {
  provider = "aws.member"
  name = "admin"
}

resource "aws_iam_group_policy_attachment" "bastion_admin" {
  provider = "aws.member"
  group = "${aws_iam_group.bastion_admin.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "bastion_admin" {
  provider = "aws.member"
  name = "dit-admin"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_sts_admin.json}"
  max_session_duration = 43200
  permissions_boundary = "${aws_iam_policy.default_admin.arn}"
}

data "aws_iam_policy_document" "bastion_sts_admin" {
  provider = "aws.member"
  statement {
    sid = "TrustBastionAccount"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.org["bastion_account"]}:root"]
    }
    condition {
      test = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = ["${var.org["organization_id"]}"]
    }
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["true"]
    }
    condition {
      test = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = ["arn:aws:iam::${var.org["bastion_account"]}:policy/dit-default-admin"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_admin" {
  provider = "aws.member"
  role = "${aws_iam_role.bastion_admin.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group" "bastion_dev" {
  provider = "aws.member"
  name = "dev"
}

resource "aws_iam_group_policy" "bastion_dev" {
  provider = "aws.member"
  name = "dev-group"
  group = "${aws_iam_group.bastion_dev.name}"
  policy = "${file("${path.module}/policies/default-policy.json")}"
}

resource "aws_iam_role" "bastion_dev" {
  provider = "aws.member"
  name = "dit-dev"
  assume_role_policy = "${data.aws_iam_policy_document.bastion_sts_dev.json}"
  max_session_duration = 43200
  permissions_boundary = "${aws_iam_policy.default_dev.arn}"
}

data "aws_iam_policy_document" "bastion_sts_dev" {
  provider = "aws.member"
  statement {
    sid = "TrustBastionAccount"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.org["bastion_account"]}:root"]
    }
    condition {
      test = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = ["${var.org["organization_id"]}"]
    }
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["true"]
    }
    condition {
      test = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = ["arn:aws:iam::${var.org["bastion_account"]}:policy/dit-default-dev"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_dev" {
  provider = "aws.member"
  role = "${aws_iam_role.bastion_dev.name}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_role_policy" "role_dev_policy" {
  provider = "aws.member"
  name = "dit-dev-policy"
  role = "${aws_iam_role.bastion_dev.name}"
  policy = "${data.aws_iam_policy_document.default_dev_policy.json}"
}

data "aws_iam_policy_document" "default_dev_policy" {
  provider = "aws.member"
  statement {
    sid = "DevAccess"
    actions = [
      "ec2:*",
      "rds:*",
      "s3:*",
      "ecs:*",
      "elasticache:*",
      "es:*",
      "lambda:*",
      "kms:List*",
      "kms:Get*",
      "kms:Describe*",
      "kms:Generate*",
      "kms:Create*",
      "kms:Encrypt*",
      "kms:Decrypt*"
    ]
    resources = ["*"]
  }
}
