data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_kms_alias" "lambda" {
  name = "alias/aws/lambda"
}

data "archive_file" "app_object" {
  type        = "zip"
  source_file = "${path.module}/src/keygen-s3-presigned-urls.py"
  output_path = "${path.module}/src/keygen-s3-presigned-urls.zip"
}


resource "aws_lambda_function" "lambda" {
  filename                       = data.archive_file.app_object.output_path
  source_code_hash               = data.archive_file.app_object.output_base64sha256
  function_name                  = "keygen-s3-presigned-urls"
  handler                        = "keygen-s3-presigned-urls.lambda_handler"
  runtime                        = "python3.9"
  timeout                        = 30
  kms_key_arn                    = data.aws_kms_alias.lambda.target_key_arn
  role                           = aws_iam_role.lambda_iam.arn
  reserved_concurrent_executions = 10

  environment {
    variables = {
      KEYGEN_ACCOUNT_ID = var.keygen_account_id
      LINK_EXPIRY_HOURS = var.link_expiry_hours
      S3_BASE_PATH      = var.s3_base_path
      S3_BUCKET         = var.s3_bucket_name
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [
    data.archive_file.app_object
  ]
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.rest_api.id}/*/*"
}

resource "aws_iam_role" "lambda_iam" {
  name = "lambda-keygen-s3-presigned-urls-access-${var.s3_bucket_name}"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [
    aws_iam_policy.lambda_access.arn,
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambda_access" {
  name        = "lambda-keygen-s3-presigned-urls-access-${var.s3_bucket_name}"
  path        = "/"
  description = "Allow the Lambda S3 Presigned URLs generator to create presigned URLs for file uploads to the '${var.s3_bucket_name}' bucket"
  policy      = data.aws_iam_policy_document.lambda_access.json
}

data "aws_iam_policy_document" "lambda_access" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [data.aws_kms_alias.lambda.target_key_arn]
  }
}


### AWS API Gateway

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "lambda-keygen-s3-presigned-urls-access-${var.s3_bucket_name}"
  description = "REST API for lambda-keygen-s3-presigned-urls"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "presigned-urls"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id          = aws_api_gateway_rest_api.rest_api.id
  resource_id          = aws_api_gateway_resource.resource.id
  http_method          = "POST"
  authorization        = "NONE"
  api_key_required     = false
  request_validator_id = aws_api_gateway_request_validator.request_validator.id
}

resource "aws_api_gateway_request_validator" "request_validator" {
  name                        = "lambda-s3-presigned-urls-access-${var.s3_bucket_name}-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.rest_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.method, aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id        = aws_api_gateway_deployment.deployment.id
  rest_api_id          = aws_api_gateway_rest_api.rest_api.id
  stage_name           = "generate"
  xray_tracing_enabled = true
}
