locals {
  # The state bucket is created by hand and already named in backend.hcl, so
  # read it from there instead of asking for it again.
  state_bucket_name = regex("(?m)^\\s*bucket\\s*=\\s*\"([^\"]+)\"", file("${path.root}/backend.hcl"))[0]

  name                 = "${var.project}-${var.environment}"
  ssm_parameter_prefix = "/${var.project}/${var.environment}"

  # Placeholders only; real values are set with the AWS CLI (see README).
  app_parameters = {
    POSTGRES_USER     = "CHANGE_ME"
    POSTGRES_PASSWORD = "CHANGE_ME"
    POSTGRES_DB       = "CHANGE_ME"
    COOKIE_SECURE     = "false"
  }
}

module "network" {
  source = "./modules/network"

  name     = local.name
  vpc_cidr = var.vpc_cidr
  app_port = var.app_port
}

module "ecr" {
  source = "./modules/ecr"

  name           = local.name
  images_to_keep = var.ecr_images_to_keep
}

module "ssm_parameters" {
  source = "./modules/ssm_parameters"

  prefix     = local.ssm_parameter_prefix
  parameters = local.app_parameters
}

module "compute" {
  source = "./modules/compute"

  name                = local.name
  subnet_id           = module.network.subnet_id
  security_group_id   = module.network.security_group_id
  internet_gateway_id = module.network.internet_gateway_id
  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  compose_version     = var.compose_version
  ecr_repository_arn  = module.ecr.arn
  parameter_path_arns = module.ssm_parameters.path_arns
}

module "github_oidc_provider" {
  source = "./modules/github_oidc_provider"
}

module "terraform_ci_role" {
  source = "./modules/terraform_ci_role"

  name               = var.project
  oidc_provider_arn  = module.github_oidc_provider.arn
  github_repo        = var.infra_repo
  github_branch      = var.infra_branch
  state_bucket_name  = local.state_bucket_name
  ssm_parameter_root = var.project
}

module "github_deploy_role" {
  source = "./modules/github_deploy_role"

  name               = local.name
  oidc_provider_arn  = module.github_oidc_provider.arn
  github_repo        = var.app_repo
  github_branch      = var.app_branch
  ecr_repository_arn = module.ecr.arn
  instance_arn       = module.compute.instance_arn
}
