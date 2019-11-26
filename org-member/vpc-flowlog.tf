data "aws_vpcs" "vpcs" {
  provider = aws.member
}

resource "aws_cloudwatch_log_group" "vpc_log" {
  provider = aws.member
  count = length(data.aws_vpcs.vpcs.ids)
  name = tolist(data.aws_vpcs.vpcs.ids)[count.index]
}

resource "aws_flow_log" "vpc_log" {
  provider = aws.member
  count = length(data.aws_vpcs.vpcs.ids)
  log_destination = tolist(aws_cloudwatch_log_group.vpc_log.*.arn)[count.index]
  iam_role_arn = aws_iam_role.vpc_log.arn
  vpc_id = tolist(data.aws_vpcs.vpcs.ids)[count.index]
  traffic_type = "ALL"
}

resource "aws_iam_role" "vpc_log" {
  provider = aws.member
  name = "vpc_log"
  assume_role_policy = file("${path.module}/policies/vpc-flowlog-sts.json")
}

resource "aws_iam_role_policy" "vpc_log_policy" {
  provider = aws.member
  name = "vpc_log_policy"
  role = aws_iam_role.vpc_log.id
  policy = file("${path.module}/policies/vpc-flowlog-role.json")
}
