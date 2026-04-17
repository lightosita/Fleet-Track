output "rule_name" {
  description = "Name of the IoT topic rule"
  value       = aws_iot_topic_rule.gps.name
}

output "iot_role_arn" {
  description = "ARN of the IoT IAM role"
  value       = aws_iam_role.iot_role.arn
}