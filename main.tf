provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
  cidr   = "10.0.0.0/16"
}

module "kinesis" {
  source      = "./modules/kinesis"
  shard_count = var.kinesis_shard_count
}

module "sqs" {
  source = "./modules/sqs"
}

module "sns" {
  source        = "./modules/sns"
  sqs_queue_arn = module.sqs.queue_arn
  alert_email   = var.alert_email
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.s3_bucket_name
}

module "timestream" {
  source = "./modules/timestream"
}

module "lambda" {
  source             = "./modules/lambda"
  kinesis_stream_arn = module.kinesis.stream_arn
  sqs_queue_arn      = module.sqs.dlq_arn
  memory_size        = var.lambda_memory_mb
}

module "iot" {
  source              = "./modules/iot"
  kinesis_stream_arn  = module.kinesis.stream_arn
  kinesis_stream_name = module.kinesis.stream_name
}

module "ecs" {
  source              = "./modules/ecs"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  kinesis_stream_arn  = module.kinesis.stream_arn
  dynamodb_table_arn  = module.dynamodb.table_arn
  dynamodb_table_name = module.dynamodb.table_name
  s3_bucket_arn       = module.s3.bucket_arn
  s3_bucket_name      = module.s3.bucket_name
  desired_count       = var.ecs_desired_count
  region              = var.region
}

module "cloudwatch" {
  source              = "./modules/cloudwatch"
  sns_topic_arn       = module.sns.topic_arn
  kinesis_stream_name = module.kinesis.stream_name
  sqs_queue_name      = module.sqs.dlq_name
}

module "apigateway" {
  source               = "./modules/apigateway"
  environment          = var.environment
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}
