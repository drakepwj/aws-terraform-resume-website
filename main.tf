terraform {
  # use_lockfile (S3-native state locking) needs Terraform 1.10+
  required_version = ">= 1.10.0"

  # Partial configuration: bucket/key/region come from backend.hcl (see backend.hcl.example)
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "frontend" {
  source = "./frontend"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  region         = var.region
  domain         = var.domain
  hosted_zone_id = var.hosted_zone_id
  visitor_api_url = module.backend.visitor_counter_api_url
}

module "backend" {
  source = "./backend"

  providers = {
    aws = aws
  }

  region         = var.region
  domain         = var.domain
  hosted_zone_id = var.hosted_zone_id
  name_suffix    = var.name_suffix
}
