output "invoke_url" {
  description = "Base invoke URL for the API Gateway stage"
  value       = aws_api_gateway_stage.fleettrack.invoke_url
}

output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.fleettrack.id
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.fleettrack.stage_name
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.fleettrack.execution_arn
}