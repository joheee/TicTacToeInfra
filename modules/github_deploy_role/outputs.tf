output "role_arn" {
  description = "Role the app pipeline assumes through OIDC."
  value       = aws_iam_role.this.arn
}
