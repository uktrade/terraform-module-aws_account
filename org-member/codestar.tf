resource "aws_codestarconnections_connection" "github" {
  provider      = aws.member
  name          = var.member.name
  provider_type = "GitHub"
  tags = {
    application         = var.member.name
    copilot-application = var.member.name
    managed-by          = "DBT SRE - Terraform"
  }
}
