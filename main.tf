provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {}
}

variable "env" {
  type = string
}

# Upload zipped NodeJS code to S3
resource "aws_s3_object" "lambda_hello_world_object" {
  bucket = data.aws_s3_bucket.hello_lambda_bucket.id

  key    = "${var.env}/hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

# IAM role for lambda
resource aws_iam_role lambda_iam_role {
    name = "lambda_iam_role_${var.env}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Cloudwatch log group for Lambda
resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.hello_world_function.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

# IAM policy to allow Cloudwatch logging from Lambda
resource "aws_iam_policy" "function_logging_policy" {
  name   = "lambda-cloudwatch-logging-policy-${var.env}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach logging policy to Lambda function
resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

# Lambda function
resource aws_lambda_function hello_world_function {
    depends_on = [ aws_iam_role.lambda_iam_role ]

    function_name = "hello_world_${var.env}"
    description = "Simple Lambda to say hello!"
    role = aws_iam_role.lambda_iam_role.arn

    s3_bucket = data.aws_s3_bucket.hello_lambda_bucket.id
    s3_key = aws_s3_object.lambda_hello_world_object.key
    source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

    runtime = "nodejs16.x"
    handler = "hello_world.handler"
}

# API Gateway
resource "aws_apigatewayv2_api" "hello_lambda_api" {
    name = "hello_lambda_api_${var.env}"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "hello_lambda_stage" {
    name = "hello_lambda_${var.env}"
    api_id = aws_apigatewayv2_api.hello_lambda_api.id
    auto_deploy = true
}

resource "aws_apigatewayv2_integration" "hello_lambda_integration" {
  api_id = aws_apigatewayv2_api.hello_lambda_api.id

  integration_uri    = aws_lambda_function.hello_world_function.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "hello_lambda_default_route" {
  api_id = aws_apigatewayv2_api.hello_lambda_api.id

  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "hello_lambda_route" {
  api_id = aws_apigatewayv2_api.hello_lambda_api.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda_integration.id}"
}

# Permissions for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway_${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.hello_lambda_api.execution_arn}/*/*"
}

# Output URL for Lambda response
output "url" {
  description = "URL for API Gateway stage."
  value = aws_apigatewayv2_stage.hello_lambda_stage.invoke_url
}