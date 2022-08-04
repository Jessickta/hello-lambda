# Zip NodeJS lambda code
data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_dir  = "${path.module}/hello_world"
  output_path = "${path.module}/hello_world.zip"
}

# S3 bucket for lambda code
data "aws_s3_bucket" "hello_lambda_bucket" {
  bucket = "hello-lambda-jta"
}