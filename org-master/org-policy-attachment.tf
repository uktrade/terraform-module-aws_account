# Organisation Policy attachments 

## Restrict SSE-C Uploads to S3. 
### At time of writing (26th Feb 2025), we only wanted to enable this on non prod OUs
### Once people are happy, we want to enable this on the root OU instead
resource "aws_organizations_policy_attachment" "restrictSSECUploads" {
  for_each = toset(var.rcp_accounts)
  policy_id = aws_organizations_policy.restrictSSECUploads.id
  target_id = aws_organizations_organizational_unit.org_ou_structure[each.key].id
}
