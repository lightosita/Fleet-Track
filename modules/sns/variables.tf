variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to subscribe to SNS alerts topic"
  type        = string
}
variable "alert_email" {
  description = "Email address to subscribe to SNS alerts"
  type        = string
}
