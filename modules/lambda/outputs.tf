output "function_arn" {
  description = "ARN of the Lambda processor function"
  value       = aws_lambda_function.processor.arn
}

output "function_name" {
  description = "Name of the Lambda processor function"
  value       = aws_lambda_function.processor.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}
output "invoke_arn" {
  description = "Invoke ARN for API Gateway integration"
  value       = aws_lambda_function.processor.invoke_arn
}
