#
# Macie classic should not be used.
#
# resource "aws_macie_member_account_association" "member" {
#   provider = aws.master
#   member_account_id = data.aws_caller_identity.member.account_id
# }
