output "stream_arn" {
  description = "ARN of the GPS Kinesis stream"
  value       = aws_kinesis_stream.gps.arn
}

output "stream_name" {
  description = "Name of the GPS Kinesis stream"
  value       = aws_kinesis_stream.gps.name
}

output "consumer_arn" {
  description = "ARN of the Kinesis stream consumer"
  value       = aws_kinesis_stream_consumer.gps_consumer.arn
}

output "consumer_name" {
  description = "Name of the Kinesis stream consumer"
  value       = aws_kinesis_stream_consumer.gps_consumer.name
}