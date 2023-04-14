# Control Tower

resource "aws_iam_role" "control_tower_execution" {
  provider = aws.common
  name = "AWSControlTowerExecution"
  assume_role_policy = data.aws_iam_policy_document.control_tower_execution.json
}

data "aws_iam_policy_document" "control_tower_execution" {
  provider = aws.common
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.org["account_id"]}:root"]
    }
  }  
}

resource "aws_iam_role_policy_attachment" "control_tower_execution_admin_access" {
  provider = aws.common
  role = aws_iam_role.control_tower_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
