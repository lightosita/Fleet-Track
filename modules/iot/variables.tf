variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream for IoT to write to"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Name of the Kinesis stream for IoT rule"
  type        = string
}