variable "aws_region" {
  description = "Region everything lives in. Must match the bootstrap region."
  type        = string
  default     = "ap-southeast-2"
}

variable "project" {
  description = "Name prefix for resources."
  type        = string
  default     = "tictactoe"
}

variable "environment" {
  description = "Environment name; also part of the SSM parameter path."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR of the VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "app_port" {
  description = "Port the app is published on (HTTP, open to the internet)."
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "EC2 instance size."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 20
}

variable "compose_version" {
  description = "Docker Compose plugin release installed by user_data."
  type        = string
  default     = "v2.29.7"
}

variable "infra_repo" {
  description = "GitHub repo (owner/name) of this Terraform repo; the only repo the Terraform CI role trusts."
  type        = string
  default     = "joheee/TicTacToeInfra"
}

variable "infra_branch" {
  description = "Branch of this repo allowed to run apply."
  type        = string
  default     = "main"
}

variable "app_repo" {
  description = "GitHub repo (owner/name) of the app pipeline allowed to assume the deploy role."
  type        = string
  default     = "joheee/TicTacToeCICD"
}

variable "app_branch" {
  description = "Branch of the app repo allowed to assume the deploy role."
  type        = string
  default     = "main"
}

variable "ecr_images_to_keep" {
  description = "Number of images kept by the ECR lifecycle policy (at least 10 so rollbacks have a target)."
  type        = number
  default     = 10

  validation {
    condition     = var.ecr_images_to_keep >= 10
    error_message = "Keep at least 10 images so a rollback target always exists."
  }
}
