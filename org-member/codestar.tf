resource "aws_codestarconnections_connection" "github"{
  provider = aws.member
  name = "conn-github"
  provider_type = "GitHub"
}