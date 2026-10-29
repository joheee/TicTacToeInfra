output "prefix" {
  description = "Parameter path holding the app's values."
  value       = var.prefix
}

output "path_arns" {
  description = "ARNs covering the path itself and everything under it, for read policies."
  value = [
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.prefix}",
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.prefix}/*",
  ]
}
