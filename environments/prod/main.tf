provider "aws" {
  region = "us-east-1"
}

module "fleettrack" {
  source = "../../"

  region              = "us-east-1"
  environment         = "prod"
  kinesis_shard_count = 10
  s3_bucket_name      = "light-teleios-fleettrack-archive"
  ecs_desired_count   = 2
  lambda_memory_mb    = 512
  alert_email         = "lightazuh75@gmail.com"
}
