output "kinesis_stream_name" {
  description = "Kinesis GPS stream name"
  value       = module.kinesis.stream_name
}

output "kinesis_stream_arn" {
  description = "Kinesis GPS stream ARN"
  value       = module.kinesis.stream_arn
}

output "dynamodb_table_name" {
  description = "DynamoDB vehicle data table name"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB vehicle data table ARN"
  value       = module.dynamodb.table_arn
}

output "sns_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = module.sns.topic_arn
}

output "s3_bucket" {
  description = "S3 archive bucket name"
  value       = module.s3.bucket_name
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.apigateway.invoke_url
}

output "lambda_function_name" {
  description = "Lambda processor function name"
  value       = module.lambda.function_name
}

output "ecs_cluster_name" {
  description = "ECS analytics cluster name"
  value       = module.ecs.cluster_name
}

# output "timestream_db" {
#   description = "Timestream database name"
#   value       = module.timestream.db_name
# }