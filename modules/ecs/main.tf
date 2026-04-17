# ECS CLUSTER
resource "aws_ecs_cluster" "fleettrack" {
  name = "fleettrack-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "fleettrack-cluster"
  }
}

# IAM ROLE FOR ECS TASK EXECUTION
resource "aws_iam_role" "ecs_execution_role" {
  name = "fleettrack-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "fleettrack-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM ROLE FOR ECS TASK (what the container can do)
resource "aws_iam_role" "ecs_task_role" {
  name = "fleettrack-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "fleettrack-ecs-task-role"
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "fleettrack-ecs-task-policy"
  description = "Allow ECS tasks to access DynamoDB, S3, and Kinesis"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Resource = var.kinesis_stream_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# CLOUDWATCH LOG GROUP FOR ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/fleettrack/ecs"
  retention_in_days = 14

  tags = {
    Name = "fleettrack-ecs-logs"
  }
}

# TASK DEFINITION
resource "aws_ecs_task_definition" "analytics" {
  family                   = "fleettrack-analytics"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "analytics"
    image     = var.container_image
    essential = true

    environment = [
      { name = "KINESIS_STREAM_ARN", value = var.kinesis_stream_arn },
      { name = "DYNAMODB_TABLE",     value = var.dynamodb_table_name },
      { name = "S3_BUCKET",          value = var.s3_bucket_name }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "fleettrack-analytics-task"
  }
}

# ECS SERVICE
resource "aws_ecs_service" "analytics" {
  name            = "fleettrack-analytics-service"
  cluster         = aws_ecs_cluster.fleettrack.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count  = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name = "fleettrack-analytics-service"
  }
}

# SECURITY GROUP FOR ECS TASKS
resource "aws_security_group" "ecs" {
  name        = "fleettrack-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "fleettrack-ecs-sg"
  }
}