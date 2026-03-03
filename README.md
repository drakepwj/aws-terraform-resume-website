This is a simple cloud project for deploying a resume website through AWS resources using Terraform and utiliziing GitHub Actions for CI/DC.

===== RESOURCES =====

=== DOMAIN PREREQUISITES ===

This project requires a registered Domain with an AWS Route 53 hosted zone. These resources are not provisioned through terraform because they require up-front costs and manual creation of the domain name.


=== FRONTEND ARCHITECTURE, TERRAFORM-MANAGED ===

S3 Bucket - set to private, holds the website files
OAC - allows CloudFront to sign requests to S3 bucket for verification
CloudFront CDN - distributes the website
ACM - certificate to enable HTTPS on CloudFront
Route 53 Records - DNS records, connects the certificate, website, and CloudFront
Bucket Policy - allows only CloudFront to read data from the bucket

=== BACKEND ARCHITECTURE, TERRAFORM-MANAGED ===

Lambda Function - Update the visitor count by 1 and returns new value
IAM Role & Policy - grants Lambda permission to read and write to DynamoDB
DynamoDB Table - Stores the visitor count
API Gateway - a public HTTPS endpoint that allows the frontend to call lambda functions
API->Lambda permission - explicit permission for the API call to the specific lambda function

===== END RESOURCES =====

===== SETUP =====

This project uses Terraform to deploy both the frontend (S3 + CloudFront + ACM + Route 53) and backend (Lambda + API Gateway). To run it in your own AWS account, you only need to provide three values: your AWS region, your domain name, and your Route 53 Hosted Zone ID.

=== 1.Prerequisites ===

Install these and configure your credentials:
AWS Cli
Terraform

Have this:
A registered domain
A Route 53 hosted zone for that domain

=== 2.Configure your variables===

Copy shared.auto.tfvars.example to shared.auto.tfvars and fill in your values

region         = "<your-aws-region>"
domain         = "<your-domain>"
hosted_zone_id = "<your-hosted-zone-id>"

*Resources like CloudFront, OAC, and ACM operate globally but only use us-east-1 as their region. They will not be affected by the region you input here and will deploy to us-east-1 with Terraform.

=== 3.
