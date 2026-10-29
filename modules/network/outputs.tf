output "subnet_id" {
  description = "Public subnet for the instance."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "App security group (HTTP only, no SSH)."
  value       = aws_security_group.app.id
}

output "internet_gateway_id" {
  description = "Internet gateway; the Elastic IP depends on it."
  value       = aws_internet_gateway.this.id
}
