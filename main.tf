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
}
