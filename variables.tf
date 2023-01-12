################################################################################
# Required Variables
################################################################################

variable "link_expiry_hours" {
  description = "After how many hours to expire the S3 pre-signed URL"
  type        = number
  default     = 6
}

variable "s3_base_path" {
  description = "The base path in the S3 bucket to generate the pre-signed URL"
  type        = string
  default     = "input"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to grant access to"
  type        = string
}

variable "keygen_account_id" {
  description = "The ID of the Keygen Account to validate license keys against"
  type        = string
}
