variable "name" {
  description = "Project name prefix"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for the static website"
  type        = string
}

variable "region" {
  description = "AWS region (used in website content)"
  type        = string
}
