variable "region" {
  type = string
}

variable "domain" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

# Appended to the backend's account/region-unique names (DynamoDB table, Lambda, IAM role) so a
# second copy of the stack can run next to an existing one. Leave empty for the original names.
variable "name_suffix" {
  type    = string
  default = ""
}
