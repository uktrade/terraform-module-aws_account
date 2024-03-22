# Setup IAM roles and policies on AWS Org member account
resource "aws_iam_policy" "default_policy" {
  provider = aws.member
  name     = "dit-default"
  policy   = file("${path.module}/policies/default-boundary-policy.json")
}

resource "aws_iam_policy" "default_dev" {
  provider = aws.member
  name     = "dit-default-dev"
  policy   = data.aws_iam_policy_document.default_dev.json
}

data "aws_iam_policy_document" "default_dev" {
  provider = aws.member
  statement {
    sid = "DevAccessBoundary"
    #checkov:skip=CKV_AWS_107:Ensure IAM policies does not allow credentials exposure
    #checkov:skip=CKV_AWS_108:Ensure IAM policies does not allow data exfiltration
    #checkov:skip=CKV_AWS_109:Ensure IAM policies does not allow permissions management / resource exposure without constraints
    #checkov:skip=CKV_AWS_110:Ensure IAM policies does not allow privilege escalation
    #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
    #checkov:skip=CKV_AWS_356:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
    actions = [
      "acm:*",
      "athena:*",
      "cloudfront:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "config:*",
      "datapipeline:*",
      "dlm:*",
      "dynamodb:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "elasticfilesystem:*",
      "es:*",
      "events:*",
      "glue:*",
      "iam:*",
      "kms:*",
      "kinesis:*",
      "lambda:*",
      "logs:*",
      "route53:*",
      "s3:*",
      "sns:*",
      "sqs:*"
    ]
    resources = ["*"]
  }
  statement {
    sid       = "DevRDSBoundary"
    actions   = ["rds:*"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "rds:DatabaseClass"
      values   = ["db.t2.small"]
    }
    condition {
      test     = "Bool"
      variable = "rds:MultiAz"
      values   = ["false"]
    }
  }
}

resource "aws_iam_group" "bastion_readonly" {
  provider = aws.member
  name     = "readonly"
}

resource "aws_iam_group_policy" "bastion_readonly" {
  provider = aws.member
  name     = "readonly-group"
  group    = aws_iam_group.bastion_readonly.name
  policy   = file("${path.module}/policies/default-policy.json")
}

resource "aws_iam_group_policy" "bastion_readonly_jump" {
  provider = aws.member
  name     = "dit-readonly-group"
  group    = aws_iam_group.bastion_readonly.name
  policy   = data.aws_iam_policy_document.bastion_readonly_jump.json
}

data "aws_iam_policy_document" "bastion_readonly_jump" {
  provider = aws.member
  statement {
    sid       = "TrustBastionAccount"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/${aws_iam_role.bastion_readonly.name}"]
  }
}

resource "aws_iam_role" "bastion_readonly" {
  provider             = aws.member
  name                 = "dit-readonly"
  assume_role_policy   = data.aws_iam_policy_document.bastion_sts_readonly.json
  max_session_duration = 43200
  permissions_boundary = aws_iam_policy.default_policy.arn
}

data "aws_iam_policy_document" "bastion_sts_readonly" {
  provider = aws.member
  statement {
    sid     = "TrustBastionAccount"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.org["bastion_account"]}:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [local.aws_organization_id]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:TokenIssueTime"
      values   = ["false"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "bastion_readonly" {
  provider   = aws.member
  role       = aws_iam_role.bastion_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "bastion_readonly_athena_read" {
  provider = aws.member
  name     = "dit-athena-readonly"
  role     = aws_iam_role.bastion_readonly.name
  policy   = data.aws_iam_policy_document.athena_read_policy.json
}

data "aws_iam_policy_document" "athena_read_policy" {
  provider = aws.member
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_356:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
  statement {
    sid = "AthenaReadOnly"
    actions = [
      "athena:Get*",
      "athena:List*",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "glue:BatchGet*",
      "glue:CheckSchemaVersionValidity",
      "glue:Get*",
      "glue:List*",
      "glue:QuerySchemaVersionMetadata",
      "glue:SearchTables"
    ]
    resources = ["*"]
  }
  statement {
    sid = "AthenaS3BucketWrite"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:CreateBucket",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::aws-athena-query-results-*"]
  }
}

resource "aws_iam_group" "bastion_admin" {
  provider = aws.member
  name     = "admin"
}

resource "aws_iam_group_policy_attachment" "bastion_admin" {
  provider   = aws.member
  group      = aws_iam_group.bastion_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
}
