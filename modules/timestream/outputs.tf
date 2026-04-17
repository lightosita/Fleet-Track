output "db_name" {
  description = "Timestream database name"
  value       = aws_timestreamwrite_database.fleettrack.database_name
}

output "db_arn" {
  description = "Timestream database ARN"
  value       = aws_timestreamwrite_database.fleettrack.arn
}

output "table_name" {
  description = "Timestream GPS table name"
  value       = aws_timestreamwrite_table.gps.table_name
}

output "table_arn" {
  description = "Timestream GPS table ARN"
  value       = aws_timestreamwrite_table.gps.arn
}