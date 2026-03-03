variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "drakepwj.click"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for drakepwj.click"
}
