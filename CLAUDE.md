# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done.

## Context

- This repo is the Terraform for portfolio project #4. The app and its CI/CD
  pipeline live in **[joheee/TicTacToeCICD](https://github.com/joheee/TicTacToeCICD)**, which consumes this repo's outputs
  as GitHub Actions variables.
- Small and cheap on purpose: one EC2 instance managed by SSM, one ECR repo,
  a minimal VPC, GitHub OIDC roles, SSM Parameter Store. No EKS, RDS or NAT.

## Layout

- The S3 state bucket is created by hand (versioned, encrypted, public access
  blocked) and is not managed by Terraform.
- Root module: wires the modules together, S3 backend with `use_lockfile = true`.
  Keep it to `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
- `modules/`: one module per concern, each with `main.tf`, `variables.tf`,
  `outputs.tf`, `versions.tf`: `network`, `ecr`, `ssm_parameters`, `compute`
  (instance role, EC2, Elastic IP), `github_oidc_provider`,
  `github_deploy_role`, `terraform_ci_role`.

## Working rules

- Never commit secrets, `*.tfstate`, `.terraform/` or `*.tfvars` with real
  values. Commit `terraform.tfvars.example` with placeholders.
- Secret values never go into Terraform: create SSM parameters with a
  placeholder and `lifecycle { ignore_changes = [value] }`.
- No SSH: no port 22 in security groups, no `key_name` on the instance.
- Least privilege: scope IAM policies to specific ARNs (the ECR repo, the
  instance, the parameter path). Explain any `"*"` resource in a comment.
- OIDC trust policies pin the exact repo and branch
  (`repo:joheee/TicTacToeCICD:ref:refs/heads/main`); never `repo:joheee/*`.
- Outputs are a contract with the app repo. Don't rename or remove the outputs
  listed in `GOALS.md`; add new ones and note them in the README.
- Pin the Terraform and provider versions in `versions.tf`.
- Run `terraform fmt` and `terraform validate` before every commit.
- Never run `terraform apply` or `destroy` without being asked; show the plan
  first.
- Tick the boxes in the GOALS.md "Definition of done" as items are finished.
