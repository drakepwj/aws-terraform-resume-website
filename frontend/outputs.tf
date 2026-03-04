output "site_bucket_name" {
  value = aws_s3_bucket.site_bucket.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "site_url" {
  value = "https://${var.domain}"
}
