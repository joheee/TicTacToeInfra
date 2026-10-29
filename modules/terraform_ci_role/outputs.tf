output "role_arn" {
  description = "Role the Terraform CI workflow assumes (set as a repo variable in this repo)."
  value       = aws_iam_role.this.arn
}
