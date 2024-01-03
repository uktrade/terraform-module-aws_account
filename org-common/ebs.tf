resource "aws_ebs_encryption_by_default" "ebs-default-encryption" {
    provider = aws.common
    enabled = true
}