output "lambda_log_group" {
  description = "Lambda CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "iot_log_group" {
  description = "IoT CloudWatch log group name"
  value       = aws_cloudwatch_log_group.iot_logs.name
}

output "lambda_error_alarm_arn" {
  description = "ARN of the Lambda error alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "kinesis_iterator_alarm_arn" {
  description = "ARN of the Kinesis iterator age alarm"
  value       = aws_cloudwatch_metric_alarm.kinesis_iterator_age.arn
}