resource "aws_guardduty_detector" "master" {
  provider = "aws.master"
  enable = true
}

resource "aws_guardduty_detector" "member" {
  provider = "aws.member"
  enable = true
}

resource "aws_guardduty_member" "org" {
  provider = "aws.member"
  account_id = "${aws_guardduty_detector.member.account_id}"
  detector_id = "${aws_guardduty_detector.master.id}"
  email = "${var.org["email"]}"
  invite = true
}
