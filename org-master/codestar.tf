resource "aws_codestarconnections_connection" "github"{
  provider = aws.master
  name = "conn-github"
  provider_type = "GitHub"
}