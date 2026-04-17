variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Kinesis stream name for iterator age alarm"
  type        = string
}

variable "sqs_queue_name" {
  description = "SQS DLQ name for depth alarm"
  type        = string
}