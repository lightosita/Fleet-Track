variable "region" {
  description = "AWS region to deploy FleetTrack"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "dev"
}

variable "kinesis_shard_count" {
  description = "Number of Kinesis shards"
  type        = number
  default     = 2
}

variable "s3_bucket_name" {
  description = "Name of the S3 archive bucket"
  type        = string
  default     = "light-teleios-fleettrack-archive"
}

variable "ecs_desired_count" {
  description = "Number of ECS Fargate task instances"
  type        = number
  default     = 1
}

variable "lambda_memory_mb" {
  description = "Memory in MB allocated to Lambda processor"
  type        = number
  default     = 256
}

variable "alert_email" {
  description = "Email address for SNS alert notifications"
  type        = string
}
