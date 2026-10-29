variable "name" {
  description = "Name prefix, e.g. tictactoe-prod."
  type        = string
}

variable "oidc_provider_arn" {
  description = "GitHub OIDC provider the role trusts."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo (owner/name) allowed to assume the role."
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to assume the role."
  type        = string
}

variable "ecr_repository_arn" {
  description = "The one ECR repository the role may push to."
  type        = string
}

variable "instance_arn" {
  description = "The one instance the role may run commands on."
  type        = string
}
