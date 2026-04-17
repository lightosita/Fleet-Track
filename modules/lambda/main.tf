# IAM ROLE
resource "aws_iam_role" "lambda_role" {
  name = "fleettrack-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "fleettrack-lambda-role"
  }
}

# CLOUDWATCH LOGS POLICY
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# KINESIS READ POLICY
resource "aws_iam_policy" "lambda_kinesis" {
  name        = "fleettrack-lambda-kinesis-policy"
  description = "Allow Lambda to read from Kinesis stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:DescribeStream",
        "kinesis:DescribeStreamSummary",
        "kinesis:ListStreams",
        "kinesis:ListShards",
        "kinesis:SubscribeToShard"
      ]
      Resource = var.kinesis_stream_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_kinesis" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_kinesis.arn
}

# SQS DLQ WRITE POLICY
resource "aws_iam_policy" "lambda_sqs" {
  name        = "fleettrack-lambda-sqs-policy"
  description = "Allow Lambda to send messages to SQS DLQ"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = var.sqs_queue_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs.arn
}

# LAMBDA FUNCTION
resource "aws_lambda_function" "processor" {
  function_name = "fleettrack-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "${path.module}/placeholder.zip"
  timeout       = 10
  memory_size   = var.memory_size

  dead_letter_config {
    target_arn = var.sqs_queue_arn
  }

  environment {
    variables = {
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Name = "fleettrack-processor"
  }
}

# KINESIS TRIGGER — TRIM_HORIZON for replay on failure
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn                   = var.kinesis_stream_arn
  function_name                      = aws_lambda_function.processor.arn
  starting_position                  = "TRIM_HORIZON"
  batch_size                         = 100
  bisect_batch_on_function_error     = true

  destination_config {
    on_failure {
      destination_arn = var.sqs_queue_arn
    }
  }
}