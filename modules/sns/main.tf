resource "aws_sns_topic" "alerts" {
  name = "fleettrack-alerts-topic"

  tags = {
    Name        = "fleettrack-alerts-topic"
    Environment = "fleettrack"
  }
}

# Subscribe SQS queue to SNS topic for reliable delivery
resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn
}
# Email subscription for operational alerts
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
