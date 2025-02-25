# 1️⃣ Try to retrieve the existing SSM parameter "private-subnets-ids"
data "aws_ssm_parameter" "existing_private_subnet_id" {
  count = length(try([data.aws_ssm_parameter.existing_private_subnet_id[0].id], [])) > 0 ? 1 : 0
  name  = "private-subnets-ids"
  provider = aws
}

# 2️⃣ Try to retrieve the existing SSM parameter "sagemaker-domain-sg"
data "aws_ssm_parameter" "existing_sg_id" {
  count = length(try([data.aws_ssm_parameter.existing_sg_id[0].id], [])) > 0 ? 1 : 0
  name  = "sagemaker-domain-sg"
  provider = aws
}

# 3️⃣ Conditionally create SSM Parameter for Private Subnet ID (Only if it does NOT exist)
resource "aws_ssm_parameter" "private_subnet_id" {
  count = length(try([data.aws_ssm_parameter.existing_private_subnet_id[0].id], [])) > 0 ? 0 : 1

  name  = "private-subnets-ids"
  type  = "StringList"
  value = join(",", [aws_subnet.private.id, aws_subnet.private_2.id])
  #   lifecycle {
  #   ignore_changes = all
  #   prevent_destroy = true
  # }
}

# 4️⃣ Conditionally create SSM Parameter for Security Group ID (Only if it does NOT exist)
resource "aws_ssm_parameter" "sg_id" {
  count = length(try([data.aws_ssm_parameter.existing_sg_id[0].id], [])) > 0 ? 0 : 1

  name  = "sagemaker-domain-sg"
  type  = "String"
  value = aws_security_group.main.id
}
