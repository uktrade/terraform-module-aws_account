# Setup CloudWatch on AWS Org account
resource "aws_cloudwatch_log_group" "master" {
  provider          = aws.master
  name              = "org"
  kms_key_id        = aws_kms_key.cloudwatch.arn
  #checkov:skip=CKV_AWS_338:Ensure CloudWatch log groups retains logs for at least 1 year
  retention_in_days = 7
}

resource "aws_kms_key" "cloudwatch" {
  provider    = aws.master
  description = "CloudWatch Key"
  policy = templatefile("${path.module}/policies/cloudwatch-kms.json",
    {
      aws_account_id = data.aws_caller_identity.master.account_id,
      aws_region     = data.aws_region.master.name
    }
  )
  #checkov:skip=CKV_AWS_7: "Ensure rotation for customer created CMKs is enabled" 
}
