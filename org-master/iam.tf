# Setup IAM roles and policies on AWS Org account
resource "aws_iam_policy" "default_policy" {
  provider = aws.master
  name = "dit-default"
  policy = file("${path.module}/policies/default-boundary-policy.json")
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
      values = [local.aws_organization_id]
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

# Sentinel

resource "aws_iam_role" "sentinel_role" {
  provider = aws.master
  name = var.soc_config["sentinel_role_name"]
  description = "Role used by the Sentinel S3 connector (https://docs.microsoft.com/en-us/azure/sentinel/connect-aws?tabs=s3)"
  assume_role_policy = data.aws_iam_policy_document.sentinel_role.json
  tags = tomap(local.sentinel_common_resource_tag)
}

data "aws_iam_policy_document" "sentinel_role" {
  provider = aws.master
  statement {
    sid = "TrustMicrosoftSentinel"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.soc_config["sentinel_account_id"]}:root"]
    }
    condition {
      test = "StringEquals"
      variable = "sts:ExternalId"
      values = [var.soc_config["sentinel_workspace_id"]]
    }
  }
}

resource "aws_iam_role_policy_attachment" "sentinel_s3_readonly" {
  provider = aws.master
  role = aws_iam_role.sentinel_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
