# Keyless deploys from GitHub Actions.
#
# The workflows in .github/workflows assume this role through GitHub's OIDC provider, so no long-lived AWS
# access keys are stored in the repository settings. The role can only be assumed by workflows running on
# the main branch of this repo, and it can only do the three things the workflows need.
#
# The OIDC provider is shared by everything in the account, so it is looked up here rather than created.

locals {
  github_repo = "drakepwj/aws-terraform-resume-website"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_deploy" {
  name = "resume-deploy-${replace(var.domain, ".", "-")}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "deploy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListSiteBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = module.frontend.bucket_arn
      },
      {
        Sid      = "UploadSiteFiles"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${module.frontend.bucket_arn}/*"
      },
      {
        Sid      = "InvalidateCache"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = module.frontend.distribution_arn
      },
      {
        Sid      = "UpdateCounterLambdaCode"
        Effect   = "Allow"
        Action   = "lambda:UpdateFunctionCode"
        Resource = module.backend.lambda_function_arn
      },
    ]
  })
}

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy.arn
}
