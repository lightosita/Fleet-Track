resource "aws_kinesis_stream" "gps" {
  name             = "fleettrack-gps-stream"
  shard_count      = var.shard_count
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
    "IteratorAgeMilliseconds"
  ]

  tags = {
    Name        = "fleettrack-gps-stream"
    Environment = "fleettrack"
  }
}

resource "aws_kinesis_stream_consumer" "gps_consumer" {
  name       = "fleettrack-gps-consumer"
  stream_arn = aws_kinesis_stream.gps.arn
}