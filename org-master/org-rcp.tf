# Resource Control Policies

## Restrict SSE-C Uploads
data "aws_iam_policy_document" "restrictSSECUploads" {
  statement {
    sid = "RestrictSSECUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["*"]
    principals {
      type = "*"
      identifiers = [ "*" ]
    }
    condition {
      test = "Null"
      variable = "s3:x-amz-server-side-encryption-customer-algorithm"
      values = ["false"]
    }
  }
}

resource "aws_organizations_policy" "restrictSSECUploads" {
  name    = "RestrictSSECUploads"
  content = data.aws_iam_policy_document.restrictSSECUploads.json
  type = "RESOURCE_CONTROL_POLICY"
}

