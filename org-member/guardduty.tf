resource "aws_guardduty_detector" "member" {
  provider = "aws.member"
  enable = true
}

resource "aws_guardduty_member" "org" {
  provider = "aws.master"
  account_id = "${aws_guardduty_detector.member.account_id}"
  detector_id = "${var.org["guardduty_id"]}"
  email = "${var.member["email"]}"
  invite = true
}
