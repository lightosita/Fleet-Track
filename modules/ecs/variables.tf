variable "vpc_id" {
  description = "VPC ID for ECS security group"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "kinesis_stream_arn" {
  description = "Kinesis stream ARN for ECS task access"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN for ECS task access"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name passed to container"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for ECS task access"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name passed to container"
  type        = string
}

variable "container_image" {
  description = "Container image URI for the analytics task"
  type        = string
  default     = "public.ecr.aws/amazonlinux/amazonlinux:latest"
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Number of ECS task instances to run"
  type        = number
  default     = 1
}

variable "region" {
  description = "AWS region for CloudWatch logs"
  type        = string
  default     = "us-east-1"
}
