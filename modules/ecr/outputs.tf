output "arn" {
  description = "Repository ARN, used to scope IAM policies."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "Where images are pushed."
  value       = aws_ecr_repository.this.repository_url
}
