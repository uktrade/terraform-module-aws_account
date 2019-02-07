resource "aws_config_config_rule" "config_rule_cloudtrail_alt" {
  provider = "aws.master.config"
  name = "cloudtrail-enabled"
  source {
    owner = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
  maximum_execution_frequency = "TwentyFour_Hours"
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_ec2_instance_alt" {
  provider = "aws.master.config"
  name = "ec2-instances-in-vpc"
  source {
    owner = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_lambda_public_prohibited_alt" {
  provider = "aws.master.config"
  name = "lambda-fucntion-public-access-prohibited"
  source {
    owner = "AWS"
    source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_db_backup_enabled_alt" {
  provider = "aws.master.config"
  name = "db-instance-backup-enabled"
  source {
    owner = "AWS"
    source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_root_mfa_alt" {
  provider = "aws.master.config"
  name = "root-account-mfa-enabled"
  source {
    owner = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  maximum_execution_frequency = "TwentyFour_Hours"
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_s3_public_read_prohibit_alt" {
  provider = "aws.master.config"
  name = "s3-bucket-public-read-prohibited"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  scope {
    tag_key = "website"
    tag_value = "false"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_s3_public_write_prohibit_alt" {
  provider = "aws.master.config"
  name = "s3-bucket-public-write-prohibited"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_s3_sse_alt" {
  provider = "aws.master.config"
  name = "s3-bucket-server-side-encryption-enabled"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  scope {
    tag_key = "website"
    tag_value = "false"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_s3_ssl_alt" {
  provider = "aws.master.config"
  name = "s3-bucket-ssl-requests-only"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
  scope {
    tag_key = "website"
    tag_value = "false"
  }
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_acm_expiration_alt" {
  provider = "aws.master.config"
  name = "acm-certificate-expiration-check"
  source {
    owner = "AWS"
    source_identifier = "ACM_CERTIFICATE_EXPIRATION_CHECK"
  }
  input_parameters = <<INPUT
    {
      "daysToExpiration": "14"
    }
  INPUT
  maximum_execution_frequency = "TwentyFour_Hours"
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}

resource "aws_config_config_rule" "config_rule_iam_password_policy_alt" {
  provider = "aws.master.config"
  name = "iam-password-policy"
  source {
    owner = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  input_parameters = <<INPUT
    {
      "RequireUppercaseCharacters": "true",
      "RequireLowercaseCharacters": "true",
      "RequireSymbols": "true",
      "RequireNumbers": "true",
      "MinimumPasswordLength": "14",
      "PasswordReusePrevention": "24",
      "MaxPasswordAge": "90"
    }
  INPUT
  maximum_execution_frequency = "TwentyFour_Hours"
  depends_on = ["aws_config_configuration_recorder.master_config_alt"]
}
