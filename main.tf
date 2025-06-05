terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket for storing findings
resource "aws_s3_bucket" "findings_bucket" {
  bucket = var.bucket_name
  force_destroy = true
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "findings_bucket_versioning" {
  bucket = aws_s3_bucket.findings_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "findings_bucket_encryption" {
  bucket = aws_s3_bucket.findings_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lambda function
resource "aws_lambda_function" "securityhub_findings_collector" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "findings_collector.lambda_handler"
  runtime         = "python3.11"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.findings_bucket.id
    }
  }
}

# CloudWatch Event Rule (EventBridge)
resource "aws_cloudwatch_event_rule" "monthly_trigger" {
  name                = "securityhub-findings-monthly-trigger"
  description         = "Triggers SecurityHub findings collection on the 1st of each month"
  schedule_expression = "cron(0 0 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_trigger.name
  target_id = "SecurityHubFindingsCollector"
  arn       = aws_lambda_function.securityhub_findings_collector.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.securityhub_findings_collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_trigger.arn
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/findings_collector.py"
  output_path = "${path.module}/findings_collector.zip"
}
