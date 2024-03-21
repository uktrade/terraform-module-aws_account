resource "aws_sqs_queue" "sentinel_flowlog_queue" {
  provider = aws.master
  name     = "microsoft-sentinel-s3-flowlog"
  tags     = tomap(local.sentinel_common_resource_tag)
  #checkov:skip=CKV_AWS_27: "Ensure all data stored in the SQS queue is encrypted"
}

resource "aws_sqs_queue" "sentinel_guardduty_queue" {
  provider = aws.master
  name     = "microsoft-sentinel-s3-guardduty"
  tags     = tomap(local.sentinel_common_resource_tag)
  #checkov:skip=CKV_AWS_27: "Ensure all data stored in the SQS queue is encrypted"
}

resource "aws_sqs_queue" "sentinel_cloudtrail_queue" {
  provider = aws.master
  name     = "microsoft-sentinel-s3-cloudtrail"
  tags     = tomap(local.sentinel_common_resource_tag)
  #checkov:skip=CKV_AWS_27: "Ensure all data stored in the SQS queue is encrypted"
}

resource "aws_sqs_queue_policy" "sentinel_flowlog_queue" {
  provider  = aws.master
  queue_url = aws_sqs_queue.sentinel_flowlog_queue.id
  policy = templatefile("${path.module}/policies/s3-sqs.json",
    {
      aws_sqs_queue_arn = aws_sqs_queue.sentinel_flowlog_queue.arn
      aws_s3_bucket_arn = aws_s3_bucket.sentinel_logs.arn
      aws_iam_role_arn  = aws_iam_role.sentinel_role.arn
    }
  )
}

resource "aws_sqs_queue_policy" "sentinel_guardduty_queue" {
  provider  = aws.master
  queue_url = aws_sqs_queue.sentinel_guardduty_queue.id
  policy = templatefile("${path.module}/policies/s3-sqs.json",
    {
      aws_sqs_queue_arn = aws_sqs_queue.sentinel_guardduty_queue.arn
      aws_s3_bucket_arn = aws_s3_bucket.sentinel_logs.arn
      aws_iam_role_arn  = aws_iam_role.sentinel_role.arn
    }
  )
}

resource "aws_sqs_queue_policy" "sentinel_cloudtrail_queue" {
  provider  = aws.master
  queue_url = aws_sqs_queue.sentinel_cloudtrail_queue.id
  policy = templatefile("${path.module}/policies/s3-sqs.json",
    {
      aws_sqs_queue_arn = aws_sqs_queue.sentinel_cloudtrail_queue.arn
      aws_s3_bucket_arn = aws_s3_bucket.sentinel_logs.arn
      aws_iam_role_arn  = aws_iam_role.sentinel_role.arn
    }
  )
}
