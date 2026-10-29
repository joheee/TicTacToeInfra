variable "name" {
  description = "Name prefix, e.g. tictactoe. The role is <name>-terraform-ci and may only manage IAM named <name>-*."
  type        = string
}

variable "oidc_provider_arn" {
  description = "GitHub OIDC provider the role trusts."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo (owner/name) of this Terraform repo; the only repo the role trusts."
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to run apply."
  type        = string
}

variable "state_bucket_name" {
  description = "Manually created S3 bucket holding the Terraform state."
  type        = string
}

variable "ssm_parameter_root" {
  description = "Top-level SSM path the stack manages, without slashes, e.g. tictactoe."
  type        = string
}
