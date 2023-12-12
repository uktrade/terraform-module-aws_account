# Create infrastructure for TF state file storage
# DynamoDB table to handle terraform state locking.
# State locks prevents multiple people from overwriting each others work.
resource "aws_dynamodb_table" "trade-tf-lockdb" {
  provider = aws.master
  name = var.tfstate_dynamodb_name # passed in from internal repo
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }
}

# S3 bucket to store the state files
# TF will pull from this bucket every time a plan or apply is run, 
# so everyone will be working from the one state file.
resource "aws_s3_bucket" "tf-state" {
  provider = aws.master
  bucket = var.tfstate_bucket_name # passed in from internal repo
}

resource "aws_s3_bucket_versioning" "tf-state_bv" {
  provider = aws.master
  bucket = aws_s3_bucket.tf-state.id 
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf-state_sse" {
  provider = aws.master
  bucket = aws_s3_bucket.tf-state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf-state_lc" {
  provider = aws.master
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.tf-state_bv]

  bucket = aws_s3_bucket.tf-state.id

  rule {
    id = "OnlyKeep20Versions"
    noncurrent_version_expiration {
      newer_noncurrent_versions = 20
      noncurrent_days = 365
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "tf-state-bucket-policy" {
  provider = aws.master
  bucket = aws_s3_bucket.tf-state.id
  policy = data.aws_iam_policy_document.tf-state-bucket-policy.json
}

# Bucket policy to prevent access to the bucket by anyone not authorised.
# The authorised users policy is passed through from the internal repo.
# This data block concats both that list and the statement together.
data "aws_iam_policy_document" "tf-state-bucket-policy" {
  source_policy_documents = [var.tfstate_policy]
   statement { # only allow secure connections to the bucket.
    sid = "Deny non-HTTPS access."
    actions = ["s3:*"]
    effect = "Deny"
    resources = ["${aws_s3_bucket.tf-state.arn}/*"]
    principals {
      type = "*"
      identifiers = ["*"]
    }
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
  }
}