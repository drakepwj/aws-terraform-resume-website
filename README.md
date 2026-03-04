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

Do this:
Clone the repository

=== 2.Configure your variables===

Copy variables.tf.example to variables.tf and fill in your values

region         = "<your-aws-region>"
domain         = "<your-domain>"
hosted_zone_id = "<your-hosted-zone-id>"

*Resources like CloudFront, OAC, and ACM operate globally but only use us-east-1 as their region. They will not be affected by the region you input here and will deploy to us-east-1 with Terraform.

=== 3.Deploy ===

Run these two to deploy:

terraform init

terraform apply

Terraform will create the frontend and backend resources, your resume website is now live.

=== 4.Enable GitHub Actions ===

This step is optional, it is for users who want to automate the deployment of updates to the resume project.

The repository includes a GitHub Actions workflow that runs Terraform automatically whenever changes are pushed. To enable it:

In your GitHub repository, go to Settings → Secrets and variables → Actions.

Add the following repository secrets:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

Commit and push any change to the repository.
This will trigger the workflow and apply the Terraform configuration for both the frontend and backend.
