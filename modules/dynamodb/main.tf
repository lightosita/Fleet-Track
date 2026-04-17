resource "aws_dynamodb_table" "vehicle_data" {
  name         = "light-teleios-fleettrack-vehicle-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "vehicle_id"
  range_key    = "timestamp"

  attribute {
    name = "vehicle_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  # Auto-expire records after TTL — DynamoDB is hot storage only
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "fleettrack-vehicle-data"
    Environment = "fleettrack"
  }
}