provider "aws" {
  region = "us-east-1"
}

module "fleettrack" {
  source = "../../"

  region              = "us-east-1"
  environment         = "dev"
  kinesis_shard_count = 2
  s3_bucket_name      = "light-teleios-fleettrack-archive"
  ecs_desired_count   = 1
  lambda_memory_mb    = 256
  alert_email         = "lightazuh75@gmail.com"
}
