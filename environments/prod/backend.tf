terraform {
  backend "s3" {
    bucket         = "light-teleios-fleettrack-state-221693237976-us-east-1"
    key            = "fleettrack/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "light-teleios-fleettrack-tf-locks"
    encrypt        = true
  }
}
