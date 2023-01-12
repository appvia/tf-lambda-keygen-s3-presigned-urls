<!-- BEGIN_TF_DOCS -->
# tf-lambda-keygen-s3-presigned-urls

This module deploys a Lambda function which validates a Keygen.sh license key and generates an S3 presigned URL for file uploads.

The Lambda expects to be passed a payload containing a license key and a ticket id for reference. Below is an example json payload when testing the Lambda function directly:

```json
{
  "body": "{\"ticketId\": \"TEST-1\",\"licenseKey\": \"keygen-license-key\"}"
}
```

When calling this through the AWS API Gateway (also deployed via this Terraform code), your json payload should look as follows:

```json
{
  "ticketId": "TEST-1",
  "licenseKey": "keygen-license-key"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_keygen_account_id"></a> [keygen\_account\_id](#input\_keygen\_account\_id) | The ID of the Keygen Account to validate license keys against | `string` | n/a | yes |
| <a name="input_link_expiry_hours"></a> [link\_expiry\_hours](#input\_link\_expiry\_hours) | After how many hours to expire the S3 pre-signed URL | `number` | `6` | no |
| <a name="input_s3_base_path"></a> [s3\_base\_path](#input\_s3\_base\_path) | The base path in the S3 bucket to generate the pre-signed URL | `string` | `"input"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the S3 bucket to grant access to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_invoke_url"></a> [api\_gateway\_invoke\_url](#output\_api\_gateway\_invoke\_url) | URL to invoke the API pointing to the presigned-urls lambda |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the lambda function |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Lambda function name |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | Invoke ARN of the lambda function |
| <a name="output_qualified_arn"></a> [qualified\_arn](#output\_qualified\_arn) | ARN identifying your Lambda Function Version |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | Lambda IAM role ARN |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Lambda IAM role name |
<!-- END_TF_DOCS -->