# One GitHub OIDC provider exists per account; both the app deploy role and the
# Terraform CI role trust it.
resource "aws_iam_openid_connect_provider" "this" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
