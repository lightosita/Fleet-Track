resource "aws_timestreamwrite_database" "fleettrack" {
  database_name = "fleettrack-timestream-db"

  tags = {
    Name        = "fleettrack-timestream-db"
    Environment = "fleettrack"
  }
}

resource "aws_timestreamwrite_table" "gps" {
  database_name = aws_timestreamwrite_database.fleettrack.database_name
  table_name    = "fleettrack-gps-data"

  retention_properties {
    memory_store_retention_period_in_hours = 24      # hot: 1 day in memory
    magnetic_store_retention_period_in_days = 365    # cold: 1 year on disk
  }

  tags = {
    Name        = "fleettrack-gps-data"
    Environment = "fleettrack"
  }
}