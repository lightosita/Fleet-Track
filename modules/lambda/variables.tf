variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream to trigger Lambda"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS Dead Letter Queue"
  type        = string
}
variable "memory_size" {
  description = "Memory in MB for the Lambda processor"
  type        = number
  default     = 256
}
