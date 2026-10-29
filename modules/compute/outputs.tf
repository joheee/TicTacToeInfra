output "instance_id" {
  description = "Instance id, the SSM Run Command target."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "Instance ARN, used to scope the deploy role."
  value       = aws_instance.this.arn
}

output "public_ip" {
  description = "Elastic IP of the instance."
  value       = aws_eip.this.public_ip
}
