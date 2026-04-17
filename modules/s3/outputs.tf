output "bucket_name" {
  description = "S3 archive bucket name"
  value       = aws_s3_bucket.archive.bucket
}

output "bucket_arn" {
  description = "S3 archive bucket ARN"
  value       = aws_s3_bucket.archive.arn
}

output "bucket_versioning_status" {
  description = "S3 bucket versioning status"
  value       = aws_s3_bucket_versioning.archive.versioning_configuration[0].status
}