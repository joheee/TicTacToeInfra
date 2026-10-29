data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Placeholders only. Real values are set once with the AWS CLI (see README);
# ignore_changes keeps them out of Terraform's way and out of the code.
resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name  = "${var.prefix}/${each.key}"
  type  = "SecureString"
  value = each.value

  lifecycle {
    ignore_changes = [value]
  }
}
