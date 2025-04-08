# datadog provider: https://registry.terraform.io/providers/DataDog/datadog/latest/docs

data "aws_caller_identity" "current" {
  provider = aws.member
}

# data "aws_iam_account_alias" "current" {
#   provider = aws.member
# }

locals {
  tags = {
    managed-by          = "DBT Platform - Terraform"
  }

  alias = var.account_alias
  # This does not work currently:
  # alias = data.aws_iam_account_alias.current.account_alias
}

resource "datadog_integration_aws_account" "datadog_integration" {
  count = var.connect_aws_account ? 1 : 0

  account_tags   = ["aws_account:${data.aws_caller_identity.current.account_id}"]
  aws_account_id = data.aws_caller_identity.current.id
  aws_partition  = "aws"
  aws_regions {
    include_only = ["eu-west-2"]
  }

  auth_config {
    aws_auth_config_role {
      role_name = "DatadogIntegrationRole"
    }
  }
  logs_config {
    lambda_forwarder {}
  }
  metrics_config {
    automute_enabled          = true
    collect_cloudwatch_alarms = true
    collect_custom_metrics    = true
    enabled                   = true
    namespace_filters {}
  }
  resources_config {}

  traces_config {
    xray_services {}
  }
}

data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  count = var.connect_aws_account ? 1 : 0

  provider = aws.member

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        "${datadog_integration_aws_account.datadog_integration[0].auth_config.aws_auth_config_role.external_id}"
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  count = var.connect_aws_account ? 1 : 0

  statement {
    actions = [
      "apigateway:GET",
      "autoscaling:Describe*",
      "backup:List*",
      "backup:ListRecoveryPointsByBackupVault",
      "bcm-data-exports:GetExport",
      "bcm-data-exports:ListExports",
      "budgets:ViewBudget",
      "cassandra:Select",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codedeploy:BatchGet*",
      "codedeploy:List*",
      "cur:DescribeReportDefinitions",
      "directconnect:Describe*",
      "dynamodb:Describe*",
      "dynamodb:List*",
      "ec2:Describe*",
      "ec2:GetSnapshotBlockPublicAccessState",
      "ec2:GetEbsDefaultKmsKeyId",
      "ec2:GetInstanceMetadataDefaults",
      "ec2:GetSerialConsoleAccessStatus",
      "ec2:GetSnapshotBlockPublicAccessState",
      "ec2:GetTransitGatewayPrefixListReferences",
      "ec2:SearchTransitGatewayRoutes",
      "ecs:Describe*",
      "ecs:List*",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeTags",
      "elasticloadbalancing:Describe*",
      "elasticmapreduce:Describe*",
      "elasticmapreduce:List*",
      "es:DescribeElasticsearchDomains",
      "es:ListDomainNames",
      "es:ListTags",
      "events:CreateEventBus",
      "fsx:DescribeFileSystems",
      "fsx:ListTagsForResource",
      "glacier:GetVaultNotifications",
      "glue:ListRegistries",
      "health:DescribeAffectedEntities",
      "health:DescribeEventDetails",
      "health:DescribeEvents",
      "keyspaces:GetTable",
      "keyspaces:ListKeyspaces",
      "keyspaces:ListTables",
      "kinesis:Describe*",
      "kinesis:List*",
      "lambda:GetPolicy",
      "lambda:List*",
      "lightsail:GetInstancePortStates",
      "logs:DeleteSubscriptionFilter",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:FilterLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:TestMetricFilter",
      "oam:ListAttachedLinks",
      "oam:ListSinks",
      "organizations:Describe*",
      "organizations:List*",
      "rds:Describe*",
      "rds:List*",
      "redshift:DescribeClusters",
      "redshift:DescribeLoggingStatus",
      "route53:List*",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAccessGrants",
      "s3:ListAllMyBuckets",
      "s3:PutBucketNotification",
      "s3express:GetBucketPolicy",
      "s3express:GetEncryptionConfiguration",
      "s3express:ListAllMyDirectoryBuckets",
      "savingsplans:DescribeSavingsPlanRates",
      "savingsplans:DescribeSavingsPlans",
      "ses:Get*",
      "secretsmanager:GetResourcePolicy",
      "sns:GetSubscriptionAttributes",
      "sns:List*",
      "sns:Publish",
      "sqs:ListQueues",
      "states:DescribeStateMachine",
      "states:ListStateMachines",
      "support:DescribeTrustedAdvisor*",
      "support:RefreshTrustedAdvisorCheck",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "timestream:DescribeEndpoints",
      "timestream:ListTables",
      "waf-regional:GetRule",
      "waf-regional:GetRuleGroup",
      "waf-regional:ListRuleGroups",
      "waf-regional:ListRules",
      "waf:GetRuleGroup",
      "waf:GetRule",
      "waf:ListRuleGroups",
      "waf:ListRules",
      "wafv2:GetIPSet",
      "wafv2:GetLoggingConfiguration",
      "wafv2:GetRegexPatternSet",
      "wafv2:GetRuleGroup",
      "wafv2:ListLoggingConfigurations",
      "xray:BatchGetTraces",
      "xray:GetTraceSummaries"
    ]
    resources = ["*"]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "datadog_aws_integration" {
  count = var.connect_aws_account ? 1 : 0

  provider = aws.member

  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration[0].json
}

resource "aws_iam_role" "datadog_aws_integration" {
  count = var.connect_aws_account ? 1 : 0

  provider = aws.member

  name               = "DatadogIntegrationRole"
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  count = var.connect_aws_account ? 1 : 0

  provider = aws.member

  role       = aws_iam_role.datadog_aws_integration[0].name
  policy_arn = aws_iam_policy.datadog_aws_integration[0].arn
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration_security_audit" {
  count = var.connect_aws_account ? 1 : 0

  provider = aws.member

  role       = aws_iam_role.datadog_aws_integration[0].name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Additional policies so that datadog can retrieve centralised billing information from the master account

data "aws_iam_policy_document" "dd_cloud_cost" {
  count = var.is_master ? 1 : 0

  provider = aws.member

  statement {
    sid    = "DDCloudCostReadBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::datadog-dbt-billing"]
  }

  statement {
    sid    = "DDCloudCostGetBill"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::datadog-dbt-billing/report/Datadog-export/*"]
  }

  statement {
    sid    = "DDCloudCostCheckAccuracy"
    effect = "Allow"
    actions = [
      "ce:Get*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DDCloudCostListCURs"
    effect = "Allow"
    actions = [
      "cur:DescribeReportDefinitions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DDCloudCostListOrganizations"
    effect = "Allow"
    actions = [
      "organizations:Describe*",
      "organizations:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_billing_policy" {
  count = var.is_master ? 1 : 0

  provider = aws.member

  name   = "DatadogAWSBillingPolicy"
  policy = data.aws_iam_policy_document.dd_cloud_cost[0].json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_billing_policy" {
  count = var.is_master ? 1 : 0

  provider = aws.member

  role       = aws_iam_role.datadog_aws_integration[0].name
  policy_arn = aws_iam_policy.datadog_billing_policy[0].arn
}
