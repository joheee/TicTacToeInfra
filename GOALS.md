# Project goals: AWS infrastructure for the EC2 CI/CD project

This repo holds the Terraform for portfolio project #4. The app and its CI/CD
pipeline live in **[joheee/TicTacToeCICD](https://github.com/joheee/TicTacToeCICD)**. This repo creates every AWS resource
that pipeline uses and nothing else. A client should be able to look at it and
think "this person sets up the AWS side cleanly, with no hand-made resources
and no stored keys".

## How the two repos fit together

| Repo | Holds |
|---|---|
| **TicTacToeInfra** (this repo) | Terraform for ECR, EC2 with SSM, networking, IAM, GitHub OIDC, SSM Parameter Store |
| **[TicTacToeCICD](https://github.com/joheee/TicTacToeCICD)** | Next.js app, Dockerfile, Compose, GitHub Actions workflows that build, push, deploy, smoke test and roll back |

The contract between them is this repo's outputs. TicTacToeCICD copies them into
its GitHub Actions repository variables:

| Terraform output | App repo variable | What it is |
|---|---|---|
| `aws_region` | `AWS_REGION` | Region everything lives in |
| `github_deploy_role_arn` | `AWS_DEPLOY_ROLE_ARN` | Role the app pipeline assumes through OIDC |
| `ecr_repository_url` | `ECR_REPOSITORY_URL` | Where images are pushed |
| `instance_id` | `EC2_INSTANCE_ID` | SSM Run Command target |
| `app_url` | `APP_URL` | Public URL for the smoke test |
| `ssm_parameter_prefix` | `SSM_PARAM_PREFIX` | Path holding the app's `.env` values |

Renaming or removing an output is a breaking change for the app repo. Add new
outputs freely; change existing ones only together with the app repo.

## Responsibilities

This repo only provisions AWS and grants permissions. The app repo owns CI and CD:
building images, pushing to ECR, deploying over SSM, smoke tests and rollback.
The deploy role here is the identity that pipeline assumes; nothing in this
repo pushes an image. Everything runs in `ap-southeast-2` because the account's
Organizations SCP restricts other regions.

## Objectives

1. **Remote state.** S3 bucket (versioned, encrypted, public access blocked)
   with S3 native state locking (`use_lockfile = true`). The bucket is created
   once by hand and is not managed by Terraform; the root module uses it as
   its remote backend.
2. **Networking, kept cheap.** A small VPC with one public subnet and an
   internet gateway (no NAT gateway). A security group that allows HTTP to the
   app port (80) and HTTPS (443, ready for the planned reverse proxy) from
   anywhere and **no SSH (port 22)**.
3. **EC2 instance managed by SSM.** Amazon Linux 2023 (SSM agent built in),
   small instance size, Elastic IP for a stable `app_url`, encrypted root
   volume, IMDSv2 required. `user_data` installs Docker and the Compose plugin
   and creates `/opt/app`. Instance profile with only: `AmazonSSMManagedInstanceCore`,
   pull from the one ECR repo, read parameters under `ssm_parameter_prefix`.
4. **ECR repository.** Scan on push, immutable tags (git SHAs never get
   overwritten), lifecycle policy that keeps at least the last 10 images so a
   rollback target always exists.
5. **GitHub OIDC for the app pipeline.** The GitHub OIDC identity provider and
   a deploy role that only `repo:joheee/TicTacToeCICD:ref:refs/heads/main` can
   assume. Least privilege: push to the one ECR repo, `ssm:SendCommand` with
   `AWS-RunShellScript` on the one instance, read the command result. No admin,
   no wildcards on resources where a specific ARN works.
6. **SSM Parameter Store for app config.** SecureString parameters under
   `/tictactoe/prod/` (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`,
   `COOKIE_SECURE`, ...). Terraform creates them with placeholder values and
   `ignore_changes` on the value, so real secrets are set once with the AWS CLI
   and never land in code or Terraform state.
7. **Terraform CI.** GitHub Actions in this repo: `fmt -check`, `validate`,
   `tflint` and `plan` on every pull request (plan posted as a PR comment);
   `apply` on merge to `main` (its output is hidden unless it fails). The workflow
   (`.github/workflows/terraform.yml`, with `.tflint.hcl`) writes `backend.hcl`
   before `init` (git-ignored locally) and reads the repo variables `AWS_REGION`,
   `TF_STATE_BUCKET` and `TF_CI_ROLE_ARN`. It uses its own OIDC role (the `terraform_ci_role`
   module) trusted only for this repo (name and branch pinned; GitHub's
   id-based token subject is matched with `@*` for the ids). No AWS keys stored anywhere.
8. **Client-style README.** Architecture diagram, the manual state bucket and first-apply steps, how to set
   the secret parameters, the outputs table above (plus the extra `terraform_ci_role_arn`), how to destroy everything,
   and a monthly cost estimate (Infracost or a hand calculation).

## Out of scope

- EKS, ECS, RDS, NAT gateways, multi-AZ, load balancers (project 1 covers the
  bigger AWS foundation). Postgres runs in Compose on the instance.
- Multiple environments. One `prod` environment is enough here; the README can
  note how a `staging` workspace or directory would be added.
- HTTPS and a custom domain setup. Port 443 is already open; the reverse proxy
  (e.g. Caddy on the instance) and the subdomain A record to the Elastic IP are
  done later, outside this repo. Until then the app pipeline keeps `COOKIE_SECURE=false`.
- Anything inside the instance beyond Docker setup. Deploys, `.env` creation and
  container restarts belong to the app pipeline over SSM.

## Plan (about 1 day)

| When | Work |
|---|---|
| Morning | Manual state bucket, VPC, subnet, security group, ECR with lifecycle policy. |
| Midday | EC2 with instance profile, user_data, Elastic IP; SSM parameters; GitHub OIDC provider and app deploy role; outputs. Confirm the instance shows as managed in SSM Fleet Manager. |
| Afternoon | Terraform CI workflow (written; needs a first local apply and repo variables), Infracost estimate, README and diagram. Hand outputs to TicTacToeCICD. |

## Tools and software

Terraform (>= 1.10) · AWS provider · Amazon S3 (state) · Amazon VPC · Amazon EC2 ·
Elastic IP · Amazon ECR · AWS IAM + GitHub OIDC · AWS Systems Manager (SSM
agent, Run Command, Parameter Store) · GitHub Actions · tflint · Infracost ·
draw.io

## Definition of done

- [ ] State bucket exists (created by hand); the main stack uses it as the S3 backend with locking and creates the GitHub OIDC provider and the Terraform CI role.
- [ ] `terraform apply` from a clean account creates everything; `terraform destroy` removes it all.
- [ ] Instance is reachable only through SSM (no port 22, no key pair) and runs Docker + Compose.
- [ ] App deploy role can push to ECR and run SSM commands on the instance, and nothing more.
- [ ] Secret values are set outside Terraform and are not in state or the repo.
- [ ] PR shows `fmt`, `validate`, `tflint` and `plan`; merge to `main` applies.
- [ ] All six outputs exist and match the app repo's variable table.
- [ ] README has the diagram, manual-bucket and destroy steps, outputs table and cost estimate.
