data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
}

# Trust is pinned to this repo only: apply from the branch, plan from pull
# requests. Never repo:joheee/*.
data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # GitHub puts numeric owner/repo ids into the subject
    # (repo:owner@<id>/name@<id>:...). StringLike lets the ids vary while the
    # owner name, repo name and ref stay pinned. The plain form is kept for
    # repos that still use the old subject format.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}",
        "repo:${var.github_repo}:pull_request",
        "repo:${split("/", var.github_repo)[0]}@*/${split("/", var.github_repo)[1]}@*:ref:refs/heads/${var.github_branch}",
        "repo:${split("/", var.github_repo)[0]}@*/${split("/", var.github_repo)[1]}@*:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-terraform-ci"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

data "aws_iam_policy_document" "permissions" {
  # State bucket: read/write objects (state + .tflock lockfile), list the bucket.
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "StateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/*"]
  }

  # IAM: only roles, policies and instance profiles named after the project.
  statement {
    sid = "ProjectIam"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy", "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
      "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile", "iam:UntagInstanceProfile", "iam:ListInstanceProfileTags",
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.name}-*",
      "arn:aws:iam::${local.account_id}:instance-profile/${var.name}-*",
    ]
  }

  # The OIDC provider is managed by this stack; CI only needs to read it to
  # refresh state. Changing it is done by hand from a local apply.
  statement {
    sid       = "ReadGithubOidcProvider"
    actions   = ["iam:GetOpenIDConnectProvider", "iam:ListOpenIDConnectProviderTags"]
    resources = [var.oidc_provider_arn]
  }

  # EC2/VPC, ECR and SSM Describe*/Get*/List* calls and several create calls do
  # not support resource-level permissions, so these services use "*". The
  # blast radius is bounded by the region condition and by IAM above being
  # limited to project-prefixed names.
  statement {
    sid = "NetworkAndCompute"
    actions = [
      "ec2:*Vpc*", "ec2:*Subnet*", "ec2:*InternetGateway*", "ec2:*RouteTable*",
      "ec2:*Route", "ec2:*SecurityGroup*", "ec2:*Address*", "ec2:*Instance*",
      "ec2:*Tags", "ec2:*Volume*", "ec2:Describe*", "ec2:ModifyInstanceMetadataOptions",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [local.region]
    }
  }

  statement {
    sid       = "Ecr"
    actions   = ["ecr:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [local.region]
    }
  }

  statement {
    sid = "ParameterStore"
    actions = [
      "ssm:PutParameter", "ssm:DeleteParameter", "ssm:GetParameter", "ssm:GetParameters",
      "ssm:AddTagsToResource", "ssm:RemoveTagsFromResource", "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.ssm_parameter_root}/*",
    ]
  }

  # The stack resolves the latest AL2023 AMI from the public AWS parameter.
  statement {
    sid       = "PublicAmiParameter"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${local.region}::parameter/aws/service/ami-amazon-linux-latest/*"]
  }

  # DescribeParameters does not support resource-level permissions.
  statement {
    sid       = "DescribeParameters"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "terraform-ci"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.permissions.json
}
