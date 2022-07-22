provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {}
}

data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_dir  = "${path.module}/hello_world"
  output_path = "${path.module}/hello_world.zip"
}

resource aws_iam_role lambda_iam_role {
    name = "lambda_iam_role"
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

resource aws_lambda_function hello_world_function {
    depends_on = [ aws_iam_role.lambda_iam_role ]

    function_name = "hello_world"
    description = "Simple Lambda to say hello!"
    role = aws_iam_role.lambda_iam_role.arn

    filename = "hello_world.zip"
    runtime = "nodejs16.x"
    handler = "hello_world.handler"
}

resource "aws_apigatewayv2_api" "hello_lambda_api" {
    name = "hello_lambda_api"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "hello_lambda_stage" {
    name = "hello_lambda_stage"
    api_id = aws_apigatewayv2_api.hello_lambda_api.id
    auto_deploy = true
}

resource "aws_apigatewayv2_integration" "hello_lambda_integration" {
  api_id = aws_apigatewayv2_api.hello_lambda_api.id

  integration_uri    = aws_lambda_function.hello_world_function.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "hello_lambda_route" {
  api_id = aws_apigatewayv2_api.hello_lambda_api.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.hello_lambda_api.execution_arn}/*/*"
}

output "url" {
  description = "URL for API Gateway stage."
  value = aws_apigatewayv2_stage.hello_lambda_stage.invoke_url
}