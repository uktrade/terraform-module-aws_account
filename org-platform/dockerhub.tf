data "aws_ssm_parameter" "dockerhub-creds-ssm" {
  provider = aws.ci

  name = "/codebuild/docker_hub_credentials"
}

resource "aws_ssm_parameter" "dockerhub-creds-ssm" {
  provider = aws.member

  name           = "/codebuild/docker_hub_credentials"
  description    = "Dockerhub credentials used by the packeto build image. Required to avoid dockerhub rate limits."
  type           = "SecureString"
  value          = data.aws_ssm_parameter.dockerhub-creds-ssm.value
  tier           = "Intelligent-Tiering"

  tags = local.ssm_tags
}
