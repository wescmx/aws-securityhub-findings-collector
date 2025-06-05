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
