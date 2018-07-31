resource "aws_config_config_rule" "config_rule_cloudtrail" {
  provider = "aws.member.config"
  name = "cloudtrail-enabled"
  source {
    owner = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
  maximum_execution_frequency = "TwentyFour_Hours"
}

resource "aws_config_config_rule" "config_rule_ec2_instance" {
  provider = "aws.member.config"
  name = "ec2-instances-in-vpc"
  source {
    owner = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }
}

resource "aws_config_config_rule" "config_rule_lambda_public_prohibited" {
  provider = "aws.member.config"
  name = "lambda-fucntion-public-access-prohibited"
  source {
    owner = "AWS"
    source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
  }
}

resource "aws_config_config_rule" "config_rule_db_backup_enabled" {
  provider = "aws.member.config"
  name = "db-instance-backup-enabled"
  source {
    owner = "AWS"
    source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
  }
}

resource "aws_config_config_rule" "config_rule_root_mfa" {
  provider = "aws.member.config"
  name = "root-account-mfa-enabled"
  source {
    owner = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  maximum_execution_frequency = "TwentyFour_Hours"
}

resource "aws_config_config_rule" "config_rule_s3_public_read_prohibit" {
  provider = "aws.member.config"
  name = "s3-bucket-public-read-prohibited"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "config_rule_s3_public_write_prohibit" {
  provider = "aws.member.config"
  name = "s3-bucket-public-write-prohibited"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
}

resource "aws_config_config_rule" "config_rule_s3_sse" {
  provider = "aws.member.config"
  name = "s3-bucket-server-side-encryption-enabled"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

resource "aws_config_config_rule" "config_rule_s3_ssl" {
  provider = "aws.member.config"
  name = "s3-bucket-ssl-requests-only"
  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
}

resource "aws_config_config_rule" "config_rule_acm_expiration" {
  provider = "aws.member.config"
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
}

resource "aws_config_config_rule" "config_rule_iam_password_policy" {
  provider = "aws.member.config"
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
}
