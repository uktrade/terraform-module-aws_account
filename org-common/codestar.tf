resource "aws_codestarconnections_connection" "github" {
  provider      = aws.common
  name          = "conn-github"
  provider_type = "GitHub"
}