# DEAD LETTER QUEUE — catches failed Lambda events and undelivered alerts
resource "aws_sqs_queue" "dlq" {
  name                      = "fleettrack-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "fleettrack-dlq"
    Environment = "fleettrack"
  }
}

# MAIN ALERTS QUEUE — receives messages from SNS
resource "aws_sqs_queue" "alerts" {
  name                       = "fleettrack-alerts-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 10    # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "fleettrack-alerts-queue"
    Environment = "fleettrack"
  }
}

# POLICY — allow SNS to send messages to this SQS queue
resource "aws_sqs_queue_policy" "alerts" {
  queue_url = aws_sqs_queue.alerts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.alerts.arn
    }]
  })
}