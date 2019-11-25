data "null_data_source" "org_member" {
  inputs = {
    account_id = "${aws_organizations_account.member.id}"
    account_arn = "${aws_organizations_account.member.arn}"
    account_email = "${var.member["email"]}"
    account_alias = "${var.member["name"]}"  }
}

output "org_master" {
  value = "${map(
            "account_id", "${aws_organizations_account.member.id}",
            "account_arn", "${aws_organizations_account.member.arn}",
            "account_email", "${var.member["email"]}",
            "account_alias", "${var.member["name"]}"
          )}"
}
