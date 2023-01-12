provider "aws" {
  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

module "lambda" {
  source = "../"

  link_expiry_hours = 1
  s3_base_path      = "s3/path"
  s3_bucket_name    = "bucket-name"
  keygen_account_id = "keygen-account-id"
}

output "arn" {
  description = "ARN of the lambda function"
  value       = module.lambda.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the lambda function"
  value       = module.lambda.invoke_arn
}

output "qualified_arn" {
  description = "ARN identifying your Lambda Function Version"
  value       = module.lambda.qualified_arn
}

output "function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "role_name" {
  description = "Lambda IAM role name"
  value       = module.lambda.role_name
}

output "role_arn" {
  description = "Lambda IAM role ARN"
  value       = module.lambda.role_arn
}

output "api_gateway_invoke_url" {
  description = "URL to invoke the API pointing to the presigned-urls lambda"
  value       = module.lambda.api_gateway_invoke_url
}
