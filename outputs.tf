output "arn" {
  description = "ARN of the lambda function"
  value       = aws_lambda_function.lambda.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the lambda function"
  value       = aws_lambda_function.lambda.invoke_arn
}

output "qualified_arn" {
  description = "ARN identifying your Lambda Function Version"
  value       = aws_lambda_function.lambda.qualified_arn
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.lambda.function_name
}

output "role_name" {
  description = "Lambda IAM role name"
  value       = aws_iam_role.lambda_iam.name
}

output "role_arn" {
  description = "Lambda IAM role ARN"
  value       = aws_iam_role.lambda_iam.arn
}

output "api_gateway_invoke_url" {
  description = "URL to invoke the API pointing to the presigned-urls lambda"
  value       = "${aws_api_gateway_stage.stage.invoke_url}/presigned-urls"
}
