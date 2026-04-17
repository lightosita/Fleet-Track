# LAMBDA LOG GROUP
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/fleettrack/lambda"
  retention_in_days = 14

  tags = {
    Name = "fleettrack-lambda-logs"
  }
}

# IOT LOG GROUP
resource "aws_cloudwatch_log_group" "iot_logs" {
  name              = "/fleettrack/iot"
  retention_in_days = 14

  tags = {
    Name = "fleettrack-iot-logs"
  }
}

# ALARM — Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "fleettrack-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda processor error rate too high"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = "fleettrack-processor"
  }

  tags = {
    Name = "fleettrack-lambda-errors-alarm"
  }
}

# ALARM — Lambda throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "fleettrack-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Lambda is being throttled"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = "fleettrack-processor"
  }

  tags = {
    Name = "fleettrack-lambda-throttles-alarm"
  }
}

# ALARM — Kinesis iterator age (processing falling behind)
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "fleettrack-kinesis-iterator-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Maximum"
  threshold           = 60000
  alarm_description   = "Kinesis stream processing is falling behind"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    StreamName = var.kinesis_stream_name
  }

  tags = {
    Name = "fleettrack-kinesis-age-alarm"
  }
}

# ALARM — DLQ depth (failed events accumulating)
resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth" {
  alarm_name          = "fleettrack-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Messages are accumulating in the Dead Letter Queue"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  tags = {
    Name = "fleettrack-dlq-alarm"
  }
}