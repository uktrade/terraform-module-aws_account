resource "aws_codestarconnections_connection" "github" {
  provider      = aws.common
  name          = var.codestar_connection_name
  provider_type = "GitHub"
  tags          = {
    copilot-application = var.codestar_connection_name
  }
}
