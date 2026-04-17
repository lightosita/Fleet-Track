variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for API Gateway integration"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to grant API Gateway invoke permission"
  type        = string
}