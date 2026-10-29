# Contract with joheee/TicTacToeCICD: these names map to its GitHub Actions
# variables. Do not rename or remove them.

output "aws_region" {
  description = "Region everything lives in (AWS_REGION)."
  value       = var.aws_region
}

output "github_deploy_role_arn" {
  description = "Role the app pipeline assumes through OIDC (AWS_DEPLOY_ROLE_ARN)."
  value       = module.github_deploy_role.role_arn
}

output "ecr_repository_url" {
  description = "Where images are pushed (ECR_REPOSITORY_URL)."
  value       = module.ecr.repository_url
}

output "instance_id" {
  description = "SSM Run Command target (EC2_INSTANCE_ID)."
  value       = module.compute.instance_id
}

output "app_url" {
  description = "Public URL for the smoke test (APP_URL)."
  value       = var.app_port == 80 ? "http://${module.compute.public_ip}" : "http://${module.compute.public_ip}:${var.app_port}"
}

output "ssm_parameter_prefix" {
  description = "Path holding the app's .env values (SSM_PARAM_PREFIX)."
  value       = module.ssm_parameters.prefix
}

# Not part of the app contract: used to configure this repo's Terraform CI.

output "terraform_ci_role_arn" {
  description = "Role the Terraform CI workflow assumes through OIDC."
  value       = module.terraform_ci_role.role_arn
}
