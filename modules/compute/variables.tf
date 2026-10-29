variable "name" {
  description = "Name prefix, e.g. tictactoe-prod."
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance in."
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to the instance."
  type        = string
}

variable "internet_gateway_id" {
  description = "Internet gateway the Elastic IP waits for."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance size."
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
}

variable "compose_version" {
  description = "Docker Compose plugin release installed by user_data."
  type        = string
}

variable "ecr_repository_arn" {
  description = "The one ECR repository the instance may pull from."
  type        = string
}

variable "parameter_path_arns" {
  description = "Parameter ARNs the instance may read."
  type        = list(string)
}
