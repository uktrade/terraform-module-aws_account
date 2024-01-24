resource "aws_ebs_encryption_by_default" "ebs_default_encryption" {
    provider = aws.common
    enabled = true
}
