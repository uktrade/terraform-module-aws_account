# Organisation Policy attachments 

## Restrict SSE-C Uploads to S3. 
resource "aws_organizations_policy_attachment" "restrictSSECUploads" {
  policy_id = aws_organizations_policy.restrictSSECUploads.id
  target_id = aws_organizations_organization.org.roots[0].id
}
