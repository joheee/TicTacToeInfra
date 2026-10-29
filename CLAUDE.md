# CLAUDE.md

Read `GOALS.md` first. It defines what this repo creates, what is out of scope
and the definition of done.

## Context

- This repo is the Terraform for portfolio project #4. The app and its CI/CD
  pipeline live in **[joheee/TicTacToeCICD](https://github.com/joheee/TicTacToeCICD)**, which consumes this repo's outputs
  as GitHub Actions variables.
- This repo only provisions AWS. CI and CD (build, push to ECR, deploy over SSM,
  smoke test, rollback) live in the app repo; here we only create the roles and
  permissions that pipeline uses. Never build or push images from this repo.
- Everything runs in `ap-southeast-2`: the account sits under an AWS Organizations
  SCP that denies other regions and some calls (e.g. `ssm:DescribeInstanceInformation`).
  An SCP denial is not fixable with an IAM policy.
- Small and cheap on purpose: one EC2 instance managed by SSM, one ECR repo,
  a minimal VPC, GitHub OIDC roles, SSM Parameter Store. No EKS, RDS or NAT.

## Layout

- The S3 state bucket is created by hand (versioned, encrypted, public access
  blocked) and is not managed by Terraform.
- Root module: wires the modules together, S3 backend with `use_lockfile = true`.
  The backend is partial: `backend.hcl` (git-ignored, copy of `backend.hcl.example`
  with `bucket` and `region`) is required for every command, and `main.tf` reads
  the bucket name from it. Do not add a `state_bucket_name` variable.
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
- No SSH: no port 22 in security groups, no `key_name` on the instance. Inbound
  is only HTTP (`app_port`, 80) and HTTPS (443, for the planned reverse proxy).
- The first `apply` runs locally because the Terraform CI role is created by
  this stack. The CI role only reads the OIDC provider; changing it is a local apply.
- Least privilege: scope IAM policies to specific ARNs (the ECR repo, the
  instance, the parameter path). Explain any `"*"` resource in a comment.
- OIDC trust policies pin the exact repo and branch
  (`repo:joheee/TicTacToeCICD:ref:refs/heads/main`); never `repo:joheee/*`.
- Outputs are a contract with the app repo. Don't rename or remove the outputs
  listed in `GOALS.md`; add new ones and note them in the README (`terraform_ci_role_arn` is the
  one extra output so far).
- Pin the Terraform and provider versions in `versions.tf`.
- Run `terraform fmt` and `terraform validate` before every commit.
- Never run `terraform apply` or `destroy` without being asked; show the plan
  first.
- Tick the boxes in the GOALS.md "Definition of done" as items are finished.
