resource "aws_guardduty_detector" "master" {
  provider = "aws.master"
  enable = true
}
