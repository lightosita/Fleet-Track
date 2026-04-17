# FleetTrack — Terraform Infrastructure
**Project:** `light-teleios` | **Naming convention:** `light-teleios-<resource>-<env>`
**State backend:** S3 bucket `light-teleios-tf-state` | DynamoDB lock table `light-teleios-db-lock`

---

## Architecture Overview

```
100,000 Vehicles (MQTT / TLS)
         │
         ▼
  ┌─────────────────┐
  │  AWS IoT Core   │  ← Device auth, topic policy, rule engine
  └────────┬────────┘
           │ Topic Rule → Kinesis (partition by vehicle_id)
           ▼
  ┌─────────────────────────────────────────┐
  │  Kinesis GPS Stream  (10 shards)        │  ← 3,333 rec/s | 48h retention
  └───────────┬─────────────────────────────┘
              │
      ┌───────┴───────┐
      │               │
      ▼               ▼
 ┌─────────┐    ┌──────────────┐
 │ Lambda  │    │ ECS Fargate  │  ← Graviton ARM64 + 70% Spot
 │ (async) │    │  (batch)     │
 └────┬────┘    └──────┬───────┘
      │                │
      ▼                ▼
 DynamoDB          Timestream         S3 Archive
 (live state)   (time-series)    (→ Glacier → Deep)
      │
      ▼
 SNS → SQS    (alerts: breakdown, overspeed, geofence)
      │
      ▼
 CloudWatch   (dashboards, alarms, X-Ray tracing)

 API Gateway  (sync: GET /vehicles, GET /fleet/status)
      │
      ▼
 CloudFront + WAFv2  (prod only — dashboard CDN)
```

---

### Architecture Principles (Event-Driven Microservices)

FleetTrack follows an event-driven microservices architecture, where each component is independently deployable and communicates asynchronously via streaming and messaging services.

Core principles applied:

### Loose coupling
No direct service-to-service calls in the ingestion/processing path. All communication flows through Kinesis, SNS, and SQS.

### Independent scalability
Each layer scales based on its own load:
IoT Core → scales automatically
Kinesis → shard-based scaling
Lambda → concurrency scaling
ECS → service auto-scaling

### Fault tolerance & replayability

Kinesis retains events for 24–48 hours
Failed consumers can replay data without loss
Bounded contexts (microservices)
Each Terraform module maps directly to a microservice boundary:
iot → ingestion
kinesis → event backbone
lambda → real-time processor
ecs → analytics service
dynamodb → state service
timestream → time-series service
s3 → archive service
api_gateway → dashboard API

---

## Project Structure

```
fleettrack/
├── backend.tf              # S3 + DynamoDB remote state config
├── main.tf                 # Root — wires all modules
├── variables.tf            # All input variables with descriptions
├── outputs.tf              # All root outputs
├── environments/
│   ├── dev/
│   │   └── main.tf         # Dev overrides (2 shards, CF disabled, 1 AZ pair)
│   └── prod/
│       └── main.tf         # Prod overrides (10 shards, CF enabled, 3 AZs)
└── modules/
    ├── vpc/                # Multi-AZ VPC, IGW, NAT GWs, route tables, SGs, VPC endpoints
    ├── iot/                # IoT Core policy, topic rule → Kinesis, error logging
    ├── kinesis/            # GPS stream + analytics stream + throttle/lag alarms
    ├── lambda/             # GPS processor, Kinesis ESM, DLQ, X-Ray, IAM (least-privilege)
    ├── ecs/                # Fargate cluster, Graviton task def, ECR, auto-scaling, IAM
    ├── dynamodb/           # Vehicle state table (TTL, GSI, PITR) + alert log table
    ├── timestream/         # GPS telemetry + driver analytics time-series tables
    ├── s3/                 # Archive (lifecycle tiers) + dashboard + Athena results buckets
    ├── sns/                # Fleet alert topic + email subscription + topic policy
    ├── sqs/                # Alert buffer queue + DLQ + SNS subscription
    ├── api_gateway/        # HTTP API v2, Lambda integration, routes, access logging
    ├── cloudfront/         # CloudFront OAC distribution + WAFv2 + security headers
    └── cloudwatch/         # Log groups, Lambda/Kinesis/ECS alarms, unified dashboard
```

---

## Prerequisites

| Tool      | Min Version | Install                          |
|-----------|-------------|----------------------------------|
| Terraform | 1.5.0       | https://developer.hashicorp.com/terraform/install |
| AWS CLI   | 2.x         | https://aws.amazon.com/cli/      |
| Docker    | Any         | Required only for ECS image push |

Configure AWS credentials before running:
```bash
aws configure
# or
export AWS_PROFILE=your-profile
```

---

## Bootstrap (Run Once — Before `terraform init`)

The S3 state bucket and DynamoDB lock table **must exist** before Terraform can initialise.
Run `scripts/bootstrap.sh` or execute the commands below manually:

```
bash scripts/bootstrap.sh
```

Or manually:

```
# 1. Create state bucket
aws s3api create-bucket \
  --bucket light-teleios-tf-state \
  --region us-east-1

# 2. Enable versioning
aws s3api put-bucket-versioning \
  --bucket light-teleios-tf-state \
  --versioning-configuration Status=Enabled

# 3. Enable encryption
aws s3api put-bucket-encryption \
  --bucket light-teleios-tf-state \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# 4. Block public access on state bucket
aws s3api put-public-access-block \
  --bucket light-teleios-tf-state \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. Create DynamoDB lock table
aws dynamodb create-table \
  --table-name light-teleios-db-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## Deployment

### terraform init
terraform validate

# Generate and review execution plan
terraform plan -out=tfplan

# Optional: save human-readable output
terraform plan -out=tfplan 2>&1 | tee plan-output.txt

# Apply reviewed plan only
terraform apply tfplan
```

---

### From Root (manual var overrides)
```
cd fleettrack/   # root of this repo
terraform init
terraform plan \
  -var="environment=prod" \
  -var="kinesis_shard_count=10" \
  -var="ecs_desired_count=2" \
  -var="enable_cloudfront=true" \
  -out=tfplan
terraform apply tfplan
```

---

### Kinesis Shard Sizing Reference

```
Vehicles:          100,000
Update frequency:  every 30 seconds
Records/sec:       100,000 ÷ 30 = 3,333 rec/s
Write per shard:   1,000 rec/s max
Minimum shards:    4 (bare minimum)
Recommended:       10 (3× headroom for traffic spikes)
```

Set `kinesis_shard_count = 10` for prod. Monitor `WriteProvisionedThroughputExceeded` in CloudWatch and add shards if the alarm fires.

---

## Lambda Deployment Package

The placeholder zip is used for `terraform plan`/`validate`. Replace before `apply`:

```bash
# Build your handler
cd src/gps-processor
npm install --production
zip -r ../../modules/lambda/lambda.zip index.js node_modules/

# Update modules/lambda/main.tf:
# filename         = "${path.module}/lambda.zip"
# source_code_hash = filebase64sha256("${path.module}/lambda.zip")
```

---

## ECS Container Deployment

```bash
# Get ECR repo URL from Terraform output
ECR_URL=$(terraform output -raw ecr_repository_url)

# Authenticate
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "$ECR_URL"

# Build (ARM64 for Graviton)
docker buildx build --platform linux/arm64 \
  -t "$ECR_URL:latest" ./src/analytics-processor --push
```

---

## Key Variables Reference

| Variable                     | Dev Default | Prod Default | Description                          |
|------------------------------|-------------|--------------|--------------------------------------|
| `project`                    | `light-teleios` | `light-teleios` | Resource name prefix              |
| `environment`                | `dev`       | `prod`       | Environment label                    |
| `kinesis_shard_count`        | `2`         | `10`         | GPS stream shards                    |
| `kinesis_retention_hours`    | `24`        | `48`         | Stream replay window                 |
| `lambda_memory_mb`           | `256`       | `512`        | Lambda processor memory              |
| `lambda_reserved_concurrency`| `50`        | `500`        | Max concurrent Lambda invocations    |
| `ecs_task_cpu`               | `1024`      | `2048`       | Fargate vCPUs (1024 = 1 vCPU)        |
| `ecs_desired_count`          | `1`         | `2`          | Minimum ECS tasks (min 2 for HA)     |
| `ecs_max_count`              | `3`         | `20`         | Auto-scaling ceiling                 |
| `enable_cloudfront`          | `false`     | `true`       | Deploy CloudFront + WAF              |
| `cloudfront_price_class`     | `PriceClass_100` | `PriceClass_All` | CDN edge coverage            |
| `s3_expiration_days`         | `365`       | `730`        | Total data retention                 |
| `alert_email`                | dev address | ops address  | SNS alarm email recipient            |

---

## Cost Optimisation Summary

| Strategy                         | Savings                         |
|----------------------------------|---------------------------------|
| Lambda Graviton (ARM64)          | ~20% cheaper vs x86             |
| ECS 70% Fargate Spot             | ~70% cheaper for batch tasks    |
| DynamoDB PAY_PER_REQUEST + TTL   | No idle cost; 7-day auto-expiry |
| S3 lifecycle (IA → Glacier → DA) | ~90% cheaper after 180 days     |
| SQS long polling (20s)           | Reduces empty receive API calls |
| Lambda reserved concurrency cap  | Prevents cost runaway           |
| CloudFront disabled in dev       | No WAF + CDN cost in dev        |

---

## Teardown

```bash
# Dev
cd environments/dev && terraform destroy

# Prod — ensure backups taken first
cd environments/prod && terraform destroy
```

> ⚠️ **Warning:** Destroying prod deletes all DynamoDB tables, Timestream data, S3 buckets (if empty), and Kinesis streams. Enable S3 object lock or DynamoDB deletion protection before running prod apply if accidental destruction is a concern.

---

### Failure Handling Strategy
IoT Core → Kinesis
Failed rules logged to CloudWatch
Kinesis
Data retained for replay (24–48h)
Lambda
Retries + DLQ (SQS)
Partial batch failure handling enabled
SQS
Dead Letter Queue isolates poison messages

---

## Observability Quick Links (after deploy)

- **CloudWatch Dashboard:** Output `cloudwatch_dashboard_url`
- **IoT Rule errors:** Log group `/aws/iot/light-teleios-<env>/rule-errors`
- **Lambda logs:** Log group `/aws/lambda/light-teleios-<env>-gps-processor`
- **ECS logs:** Log group `/ecs/light-teleios-<env>/analytics`
- **API Gateway logs:** Log group `/aws/apigateway/light-teleios-<env>`

---

### Scalability Summary

FleetTrack achieves horizontal scalability through:

Kinesis shard scaling → handles ingestion spikes
Lambda concurrency scaling → real-time processing
ECS auto scaling (2–20 tasks) → batch workloads
Stateless services → no shared memory dependencies
Event-driven design → zero tight coupling