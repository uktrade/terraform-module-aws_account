# A cross account monitoring role

data "aws_iam_policy_document" "cloudwatch-monitoring-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::480224066791:role/cloudwatch-exporter-prod-exporter-TaskRole"]
    }
  }
}

resource "aws_iam_role" "cloudwatch-monitoring-role" {
  name               = "cloudwatch-monitoring-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "cloudwatch-monitoring-policy" {
  name = "test_policy"
  role = aws_iam_role.cloudwatch-monitoring-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "tag:GetResources",
            "cloudwatch:GetMetricData",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics",
            "apigateway:GET",
            "aps:ListWorkspaces",
            "autoscaling:DescribeAutoScalingGroups",
            "dms:DescribeReplicationInstances",
            "dms:DescribeReplicationTasks",
            "ec2:DescribeTransitGatewayAttachments",
            "ec2:DescribeSpotFleetRequests",
            "shield:ListProtections",
            "storagegateway:ListGateways",
            "storagegateway:ListTagsForResource",
            "iam:ListAccountAliases",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
