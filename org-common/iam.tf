# Control Tower

resource "aws_iam_role" "control_tower_execution" {
  provider           = aws.common
  name               = "AWSControlTowerExecution"
  assume_role_policy = data.aws_iam_policy_document.control_tower_execution.json
}

data "aws_iam_policy_document" "control_tower_execution" {
  provider = aws.common
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.org["account_id"]}:root"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "control_tower_execution_admin_access" {
  provider   = aws.common
  role       = aws_iam_role.control_tower_execution.name
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Delegated IAM User Manager Policy

resource "aws_iam_policy" "iam_user_manager" {
  provider    = aws.common
  name        = "dit-iam-manager"
  description = "Policy for IAM delegated manager access."
  policy      = data.aws_iam_policy_document.iam_user_manager.json
}

data "aws_iam_policy_document" "iam_user_manager" {
  provider = aws.common
  statement {
    sid    = "UserManagerViewAndDeleteIAMResources"
    effect = "Allow"
    actions = [
      "iam:ListGroupsForUser",
      "iam:ListMFADevices",
      "iam:ListAttachedUserPolicies",
      "iam:ListUserTags",
      "iam:ListAccessKeys",
      "iam:ListServiceSpecificCredentials",
      "iam:ListUserPolicies",
      "iam:ListSigningCertificates",
      "iam:ListSSHPublicKeys",
      "iam:GetUser",
      "iam:GetUserPolicy",
      "iam:GetLoginProfile",
      "iam:DeleteUser",
      "iam:DeleteSSHPublicKey",
      "iam:DeleteLoginProfile",
      "iam:DeleteSigningCertificate",
      "iam:DeleteServiceSpecificCredential",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.common.account_id}:user/*"]
  }
  statement {
    sid    = "UserManagerViewAndDeleteAllResources"
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListUsers",
      "iam:ListPolicies",
      "iam:GetAccountSummary",
      "sso-directory:ListMfaDevicesForUser",
      "sso-directory:ListGroupsForUser",
      "sso-directory:SearchUsers",
      "sso-directory:DescribeUsers",
      "sso-directory:DescribeDirectory",
      "sso-directory:DescribeUserByUniqueAttribute",
      "sso-directory:DescribeUser",
      "sso-directory:DescribeGroups",
      "sso-directory:DisableUser",
      "sso-directory:DeleteUser",
      "sso-directory:DeleteMfaDeviceForUser",
      "sso:ListInstances",
      "sso:ListDirectoryAssociations",
      "sso:GetSsoConfiguration",
      "sso:GetSSOStatus",
      "sso:DisassociateProfile",
      "sso:DescribeRegisteredRegions",
      "sso:GetMfaDeviceManagementForDirectory",
      "ec2:DescribeRegions",
      "notifications:ListNotificationHubs"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "UserManagerViewAndGetSSOResources"
    effect = "Allow"
    actions = [
      "sso:DescribeInstance",
      "sso:GetPermissionsBoundaryForPermissionSet"
    ]
    resources = [
      "arn:aws:sso:::instance/*",
      "arn:aws:sso:::permissionSet/*/*"
    ]
  }
}

resource "aws_iam_account_password_policy" "strict" {
  provider                       = aws.common
  #checkov:skip=CKV_AWS_10:Ensure IAM password policy requires minimum length of 14 or greater
  minimum_password_length        = var.password_policy_minimum_password_length
  require_lowercase_characters   = var.password_policy_require_lowercase_characters
  require_numbers                = var.password_policy_require_numbers
  require_uppercase_characters   = var.password_policy_require_uppercase_characters
  require_symbols                = var.password_policy_require_symbols
  allow_users_to_change_password = var.password_policy_allow_users_to_change_password
  #checkov:skip=CKV_AWS_9:Ensure IAM password policy expires passwords within 90 days or less
  max_password_age               = var.password_policy_max_password_age
  password_reuse_prevention      = var.password_policy_password_reuse_prevention
}
