resource "aws_api_gateway_rest_api" "fleettrack" {
  name        = "fleettrack-api"
  description = "FleetTrack dashboard and admin API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name        = "fleettrack-api"
    Environment = var.environment
  }
}

resource "aws_api_gateway_resource" "vehicles" {
  rest_api_id = aws_api_gateway_rest_api.fleettrack.id
  parent_id   = aws_api_gateway_rest_api.fleettrack.root_resource_id
  path_part   = "vehicles"
}

resource "aws_api_gateway_method" "get_vehicles" {
  rest_api_id   = aws_api_gateway_rest_api.fleettrack.id
  resource_id   = aws_api_gateway_resource.vehicles.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_vehicles" {
  rest_api_id             = aws_api_gateway_rest_api.fleettrack.id
  resource_id             = aws_api_gateway_resource.vehicles.id
  http_method             = aws_api_gateway_method.get_vehicles.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_resource" "alerts" {
  rest_api_id = aws_api_gateway_rest_api.fleettrack.id
  parent_id   = aws_api_gateway_rest_api.fleettrack.root_resource_id
  path_part   = "alerts"
}

resource "aws_api_gateway_method" "get_alerts" {
  rest_api_id   = aws_api_gateway_rest_api.fleettrack.id
  resource_id   = aws_api_gateway_resource.alerts.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_alerts" {
  rest_api_id             = aws_api_gateway_rest_api.fleettrack.id
  resource_id             = aws_api_gateway_resource.alerts.id
  http_method             = aws_api_gateway_method.get_alerts.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "fleettrack" {
  rest_api_id = aws_api_gateway_rest_api.fleettrack.id
  depends_on = [
    aws_api_gateway_integration.get_vehicles,
    aws_api_gateway_integration.get_alerts
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/fleettrack/apigateway/${var.environment}"
  retention_in_days = 14
  tags = {
    Name        = "fleettrack-api-logs"
    Environment = var.environment
  }
}

resource "aws_api_gateway_stage" "fleettrack" {
  rest_api_id   = aws_api_gateway_rest_api.fleettrack.id
  deployment_id = aws_api_gateway_deployment.fleettrack.id
  stage_name    = var.environment
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = "$context.requestId $context.identity.sourceIp $context.httpMethod $context.resourcePath $context.status $context.responseLength"
  }
  tags = {
    Name        = "fleettrack-api-stage-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fleettrack.execution_arn}/*/*"
}

resource "aws_api_gateway_usage_plan" "fleettrack" {
  name        = "fleettrack-usage-plan-${var.environment}"
  description = "FleetTrack API rate limiting"
  api_stages {
    api_id = aws_api_gateway_rest_api.fleettrack.id
    stage  = aws_api_gateway_stage.fleettrack.stage_name
  }
  throttle_settings {
    burst_limit = 500
    rate_limit  = 100
  }
  quota_settings {
    limit  = 10000
    period = "DAY"
  }
}
