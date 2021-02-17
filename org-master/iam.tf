# Setup IAM roles and policies on AWS Org account
resource "aws_iam_policy" "default_policy" {
  provider = aws.master
  name = "dit-default"
  policy = file("${path.module}/policies/default-boundary-policy.json")
}

resource "aws_iam_policy" "default_admin" {
  provider = aws.master
  name = "dit-default-admin"
  policy = data.aws_iam_policy_document.default_admin.json
}

data "aws_iam_policy_document" "default_admin" {
  provider = aws.master
  statement {
    actions = ["*"]
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
      values = ["eu-west-1", "eu-west-2", "us-east-1"]
    }
  }
  statement {
    sid = "DisableOtherRegions"
    effect = "Deny"
    not_actions = [
      "aws-portal:*",
      "iam:*",
      "organizations:*",
      "support:*",
      "sts:*"
    ]
    resources = ["*"]
    condition {
      test = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = ["eu-west-1", "eu-west-2"]
    }
  }
}

resource "aws_iam_group" "bastion_readonly" {
  provider = aws.master
  name = "readonly"
}

resource "aws_iam_group_policy" "bastion_readonly" {
  provider = aws.master
  name = "readonly-group"
  group = aws_iam_group.bastion_readonly.name
  policy = file("${path.module}/policies/default-policy.json")
}

resource "aws_iam_role" "bastion_readonly" {
  provider = aws.master
  name = "dit-readonly"
  assume_role_policy = data.aws_iam_policy_document.bastion_sts_readonly.json
  max_session_duration = 43200
  permissions_boundary = aws_iam_policy.default_policy.arn
}

data "aws_iam_policy_document" "bastion_sts_readonly" {
  provider = aws.master
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
      values = [element(split("/", aws_organizations_organization.org.id), 1)]
    }
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["true"]
    }
    condition {
      test = "Null"
      variable = "aws:TokenIssueTime"
      values = ["false"]
    }
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["true"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_readonly" {
  provider = aws.master
  role = aws_iam_role.bastion_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_group" "bastion_admin" {
  provider = aws.master
  name = "admin"
}

resource "aws_iam_group_policy_attachment" "bastion_admin" {
  provider = aws.master
  group = aws_iam_group.bastion_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "bastion_admin" {
  provider = aws.master
  name = "dit-admin"
  assume_role_policy = data.aws_iam_policy_document.bastion_sts_admin.json
  max_session_duration = 43200
  permissions_boundary = aws_iam_policy.default_admin.arn
}

data "aws_iam_policy_document" "bastion_sts_admin" {
  provider = aws.master
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
      values = [element(split("/", aws_organizations_organization.org.id), 1)]
    }
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["true"]
    }
    condition {
      test = "Null"
      variable = "aws:TokenIssueTime"
      values = ["false"]
    }
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["true"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_admin" {
  provider = aws.master
  role = aws_iam_role.bastion_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
