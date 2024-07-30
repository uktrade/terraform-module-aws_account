resource "aws_codestarconnections_connection" "github" {
  provider      = aws.common
  name          = var.codestar_connection_name
  provider_type = "GitHub"
  tags = {
    application         = var.codestar_connection_name
    copilot-application = var.codestar_connection_name
    managed-by          = "DBT SRE - Terraform"
  }
}
