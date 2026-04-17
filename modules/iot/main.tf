# IAM ROLE FOR IOT → KINESIS
resource "aws_iam_role" "iot_role" {
  name = "fleettrack-iot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "iot.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "fleettrack-iot-role"
  }
}

# POLICY — allow IoT to put records into Kinesis
resource "aws_iam_policy" "iot_kinesis" {
  name        = "fleettrack-iot-kinesis-policy"
  description = "Allow IoT Core to write GPS records to Kinesis"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kinesis:PutRecord", "kinesis:PutRecords"]
      Resource = var.kinesis_stream_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "iot_kinesis" {
  role       = aws_iam_role.iot_role.name
  policy_arn = aws_iam_policy.iot_kinesis.arn
}

# IOT TOPIC RULE — forward GPS telemetry into Kinesis
resource "aws_iot_topic_rule" "gps" {
  name        = "fleettrack_gps_rule"
  enabled     = true
  sql         = "SELECT * FROM 'fleet/gps'"
  sql_version = "2016-03-23"

  kinesis {
    stream_name = var.kinesis_stream_name
    role_arn    = aws_iam_role.iot_role.arn
    partition_key = "$${clientId()}"
  }

  error_action {
    cloudwatch_logs {
      log_group_name = "/aws/iot/fleettrack-errors"
      role_arn       = aws_iam_role.iot_role.arn
    }
  }

  tags = {
    Name = "fleettrack-gps-rule"
  }
}