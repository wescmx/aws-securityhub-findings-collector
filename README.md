# SecurityHub Findings Collector

This Terraform configuration sets up an automated system to collect AWS SecurityHub findings on a monthly basis. The system consists of:

1. A Lambda function that collects SecurityHub findings
2. An S3 bucket to store the findings
3. An EventBridge rule that triggers the Lambda function monthly
4. Required IAM roles and policies

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.2.0
- AWS account with SecurityHub enabled

## Configuration

1. Update the `terraform.tfvars` file with the following variables:
   ```hcl
   aws_region = "your-region"  # Required, specify your AWS region
   bucket_name = "your-bucket-name"  # Required, must be globally unique
   lambda_function_name = "your-function-name"  # Required, name for the Lambda function
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the planned changes:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Features

- Collects CRITICAL and HIGH severity findings from SecurityHub
- Runs automatically on the 1st of each month
- Stores findings in both JSON and CSV formats
- Files are named with the format `bucket_name/YYYY-MM-DD.{json,csv}`
- Includes proper error handling and pagination for large result sets

## Output Files

The Lambda function generates two files for each run in the following structure:
```
s3://bucket_name/YYYY-MM-DD/findings.json  # Raw JSON data of all findings
s3://bucket_name/YYYY-MM-DD/findings.csv   # CSV format with key finding information
```

For example, with bucket name "securityhub-findings", files created on May 1st, 2024 (containing April's findings) would be:
```
s3://securityhub-findings/2024-05-01/findings.json
s3://securityhub-findings/2024-05-01/findings.csv
```

## Security Features

- S3 bucket with versioning enabled
- Server-side encryption enabled by default
- Least privilege IAM roles and policies
- Secure Lambda execution environment

## Cleanup

To remove all resources, including the S3 bucket and its contents:
```bash
terraform destroy
```
