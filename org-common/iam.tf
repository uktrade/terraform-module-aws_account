# Control Tower

resource "aws_iam_role" "control_tower_execution" {
  provider = aws.common
  name = "AWSControlTowerExecution"
  assume_role_policy = data.aws_iam_policy_document.control_tower_execution.json
}

data "aws_iam_policy_document" "control_tower_execution" {
  provider = aws.common
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.org["account_id"]}:root"]
    }
  }  
}

resource "aws_iam_role_policy_attachment" "control_tower_execution_admin_access" {
  provider = aws.common
  role = aws_iam_role.control_tower_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Delegated IAM User Manager Policy

resource "aws_iam_policy" "iam_user_manager" {
  provider = aws.common
  name = "dit-iam-manager"
  description = "Policy for IAM delegated manager access."
  policy = data.aws_iam_policy_document.iam_user_manager.json
}

data "aws_iam_policy_document" "iam_user_manager" {
  provider = aws.common
  statement {
    effect = "Allow"
    actions = [
        "iam:ListAccountAliases",
				"iam:ListUsers",
				"iam:ListGroupsForUser",
        "iam:ListMFADevices",
				"iam:ListAttachedUserPolicies",
				"iam:ListUserTags",
        "iam:ListAccessKeys",
        "iam:ListPolicies",
        "iam:ListServiceSpecificCredentials",
        "iam:ListUserPolicies",
        "iam:ListSigningCertificates",
        "iam:ListSSHPublicKeys",
        "iam:GetAccountSummary",
				"iam:GetUser",
				"iam:GetUserPolicy",
        "iam:GetLoginProfile",
				"iam:DeleteUser",
        "iam:DeleteSSHPublicKey",
        "iam:DeleteSigningCertificate",
        "iam:DeleteServiceSpecificCredential",
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
        "sso:DisassociateProfile"
			]
    resources = ["*"]
  }  
}
