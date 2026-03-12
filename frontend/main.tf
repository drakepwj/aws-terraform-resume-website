terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 bucket for static site (private)
resource "aws_s3_bucket" "site_bucket" {
  bucket = "resume-${var.domain}"
}

resource "aws_s3_bucket_ownership_controls" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "site_bucket" {
  bucket                  = aws_s3_bucket.site_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control for CloudFront → S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "resume-oac"
  description                       = "OAC for resume site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ACM certificate for drakepwj.click (in us-east-1)
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}


# ACM Cert validation
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "resume.html"

  origin {
    domain_name              = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain]
}

# Allow CloudFront to read from S3
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# Route53 alias to CloudFront
resource "aws_route53_record" "root_alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Rewrite GitHub Actions Workflow with your domain
resource "null_resource" "update_workflow" {
  triggers = {
    always = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOT
      sed -i 's|AWS_S3_BUCKET:.*|AWS_S3_BUCKET: resume-${var.domain}|' ${path.module}/../.github/workflows/deploy-frontend.yml
      sed -i 's|AWS_REGION:.*|AWS_REGION: ${var.region}|g' ${path.module}/../.github/workflows/deploy-frontend.yml
      sed -i 's|--distribution-id [A-Z0-9]*|--distribution-id ${aws_cloudfront_distribution.cdn.id}|' ${path.module}/../.github/workflows/deploy-frontend.yml
      sed "s|VISITOR_API_URL|${var.visitor_api_url}|g" ${path.module}/counter.js > /tmp/counter.js
      aws s3 cp /tmp/counter.js s3://resume-${var.domain}/counter.js
      aws s3 cp ${path.module}/resume.html s3://resume-${var.domain}/resume.html
      aws s3 cp ${path.module}/style.css s3://resume-${var.domain}/style.css
    EOT
  }
}
