resource "aws_config_configuration_aggregator" "master_alt" {
  provider = "aws.master.config"
  name = "aws-org-config"
  organization_aggregation_source {
    all_regions = true
    role_arn = "${aws_iam_role.master_config_role.arn}"
  }
  depends_on = ["aws_iam_role_policy_attachment.config_organization"]
}

resource "aws_config_configuration_recorder" "master_config_alt" {
  provider = "aws.master.config"
  name = "config-${data.aws_caller_identity.master.account_id}"
  role_arn = "${aws_iam_role.master_config_role.arn}"
  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "master_config_alt" {
  provider = "aws.master.config"
  name = "${aws_config_configuration_recorder.master_config_alt.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.master_alt"]
}

resource "aws_config_delivery_channel" "master_alt" {
  provider = "aws.master.config"
  name = "aws-config-${data.aws_caller_identity.master.account_id}"
  s3_bucket_name = "${aws_s3_bucket.master_config_bucket.id}"
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_sns_topic" "config_sns_alt" {
  provider = "aws.master.config"
  name = "org-config-sns"
}

resource "aws_sns_topic_policy" "config_sns_alt" {
  provider = "aws.master.config"
  arn = "${aws_sns_topic.config_sns_alt.id}"
  policy = "${data.aws_iam_policy_document.config_sns_policy_alt.json}"
}

data "aws_iam_policy_document" "config_sns_policy_alt" {
  provider = "aws.master.config"
  statement {
    sid = "Default SNS policy"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    condition {
      test = "StringEquals"
      variable = "AWS:SourceOwner"
      values = ["${data.aws_caller_identity.master.account_id}"]
    }
    resources = ["${aws_sns_topic.config_sns_alt.id}"]
  }

  statement {
    sid = "Allow AWS Config to publish events"
    actions = ["SNS:Publish"]
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_role.master_config_role.arn}"]
    }
    resources = ["${aws_sns_topic.config_sns_alt.id}"]
  }

  statement {
    sid = "Allow CloudWatch Events to publish"
    actions = ["SNS:Publish"]
    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = ["${aws_sns_topic.config_sns_alt.id}"]
  }
}

resource "aws_iam_role_policy" "config_sns_policy_alt" {
  provider = "aws.master"
  name = "config_sns_policy_alt"
  role = "${aws_iam_role.master_config_role.name}"
  policy = "${data.aws_iam_policy_document.config_sns_alt.json}"
}

data "aws_iam_policy_document" "config_sns_alt" {
  provider = "aws.master"
  statement {
    sid = "DefaultPolicyForAWSConfig"
    actions = ["SNS:Publish"]
    resources = ["${aws_sns_topic.config_sns_alt.id}"]
  }
}
