resource "aws_cloudformation_stack" "account_wide_logs_data_protection_policy" {
  provider = aws.common
  name     = "AccountWideDataProtectionLogsPolicy"

  template_body = jsonencode({
    Resources = {
      AccountPolicy = {
        Type = "AWS::Logs::AccountPolicy"
        Properties = {
          PolicyName = "AccountWideDataProtectionLogsPolicy"
          PolicyType = "DATA_PROTECTION_POLICY"
          Scope      = "ALL"
          PolicyDocument = jsonencode({
            Name        = "ACCOUNT_DATA_PROTECTION_POLICY"
            Description = ""
            Version     = "2021-06-01"
            Configuration = {
              CustomDataIdentifier = [
                {
                  Name  = "Password"
                  Regex = "(\"password\":\\s*\")([^\"]+)(\")"
                },
                {
                  Name  = "SecretKey"
                  Regex = "(SECRET_KEY=)([^\\s]+)"
                }
              ]
            }
            Statement = [
              {
                Sid = "audit-policy"
                DataIdentifier = [
                  "arn:aws:dataprotection::aws:data-identifier/AwsSecretKey",
                  "arn:aws:dataprotection::aws:data-identifier/OpenSshPrivateKey",
                  "Password",
                  "SecretKey"
                ]
                Operation = {
                  Audit = {
                    FindingsDestination = {}
                  }
                }
              },
              {
                Sid = "redact-policy"
                DataIdentifier = [
                  "arn:aws:dataprotection::aws:data-identifier/AwsSecretKey",
                  "arn:aws:dataprotection::aws:data-identifier/OpenSshPrivateKey",
                  "Password",
                  "SecretKey"
                ]
                Operation = {
                  Deidentify = {
                    MaskConfig = {}
                  }
                }
              }
            ]
          })
        }
      }
    }
  })
}
