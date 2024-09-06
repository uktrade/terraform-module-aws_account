#Observability Access Manager
# To enable Cross-account CloudWatch visibility. 
# This allows us to monitor all CloudWatch stats from a single account rather than switching between multiple ones.

# Create a 'sink' in the account you wish to monitor from
resource "aws_oam_sink" "sink" {
  provider = aws.member
  count    = try(var.member.cw_monitoring_account, false) == true ? 1 : 0
  name     = "org-sink"
}

# Apply a policy to allow any account within our AWS Orgaization to access it.
resource "aws_oam_sink_policy" "sink-policy" {
  provider        = aws.member
  count           = try(var.member.cw_monitoring_account, false) == true ? 1 : 0
  sink_identifier = aws_oam_sink.sink[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["oam:CreateLink", "oam:UpdateLink"]
        Effect    = "Allow"
        Resource  = "*"
        Principal = "*"
        Condition = {
          "StringEquals" = {
            "aws:PrincipalOrgID" = [data.aws_organizations_organization.org.id]
          }
        }
      }
    ]
  })
}

resource "aws_ssm_parameter" "oam-sink-id" {
  provider    = aws.ci
  count       = try(var.member.cw_monitoring_account, false) == true ? 1 : 0
  name        = "/observability/sink/id"
  description = "Sink ID from monitoring account"
  type        = "SecureString"
  value       = aws_oam_sink.sink[0].id
  key_id      = "alias/trade-terraform-parameter-store-key"
}

# The above ssm parameter resource won't exist for non-monitoring accounts,
# So lets pull it down when we're dealing with a non-monitoring account.
data "aws_ssm_parameter" "oam-sink-id" {
  provider = aws.ci
  count    = try(var.member.cw_monitoring_account, false) == false ? 1 : 0
  name     = "/observability/sink/id"
}

# Create a link to the sink created above from all other accounts:
resource "aws_oam_link" "link" {
  provider        = aws.member
  count           = try(var.member.cw_monitoring_account, false) == false ? 1 : 0
  label_template  = "$AccountName"
  resource_types  = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup"]
  sink_identifier = data.aws_ssm_parameter.oam-sink-id[0].value
}
