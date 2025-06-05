bucket_name = "securityhub-findings"
aws_region = "us-east-1"
lambda_function_name = "securityhub-findings-collector"
findings_schedule = "cron(0 0 1 * ? *)"  # Monthly on the 1st at midnight UTC

# Other schedule examples:
# findings_schedule = "cron(0 0 * * ? *)"     # Daily at midnight UTC
# findings_schedule = "cron(0 0 ? * MON *)"   # Weekly on Mondays at midnight UTC
