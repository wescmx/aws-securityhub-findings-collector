variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to store SecurityHub findings"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "findings_schedule" {
  description = "Schedule expression for when to collect findings. Examples: cron(0 0 * * ? *) for daily, cron(0 0 ? * MON *) for weekly, cron(0 0 1 * ? *) for monthly"
  type        = string
}
