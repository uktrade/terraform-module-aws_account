locals {
  tags = {
    managed-by = "DBT Platform - Terraform"
  }

  prod = {
    assume_role = "arn:aws:iam::480224066791:role/amp-prometheus-role"
    endpoint = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-7297af06-7c1a-4bfc-affd-4abe053797e16e/api/v1/remote_write"
  }

  dev = {
    assume_role = "arn:aws:iam::480224066791:role/amp-prometheus-dev-role"
    endpoint = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-d9fd4d97-49cc-4b89-9f4c-025e275704eec6/api/v1/remote_write"
  }
}

resource "aws_ssm_parameter" "adot-prometheus-dev-config" {
  provider        = aws.member

  name            = "/observability/prometheus-dev/adot_config"
  description     = "Configuration to enable the ADOT sidecar image to ship ECS container metrics into Prometheus."
  type            = "String"
  insecure_value  = templatefile("${path.module}/adot-prometheus-config.yaml.tmpl", local.dev)
  tier            = "Intelligent-Tiering"

  tags = local.tags
}

resource "aws_ssm_parameter" "adot-prometheus-config" {
  provider        = aws.member

  name            = "/observability/prometheus/adot_config"
  description     = "Configuration to enable the ADOT sidecar image to ship ECS container metrics into Prometheus."
  type            = "String"
  insecure_value  = templatefile("${path.module}/adot-prometheus-config.yaml.tmpl", local.prod)
  tier            = "Intelligent-Tiering"

  tags = local.tags
}
