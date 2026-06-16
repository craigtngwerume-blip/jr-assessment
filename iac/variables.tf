variable "region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "name" {
  description = "Project name prefix"
  type        = string
  default     = "jr-assessment"
}

variable "owner" {
  description = "Owner tag value"
  type        = string
  default     = "craig"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 10
}

variable "my_ip" {
  description = "Your public IP for SSH access (e.g. 1.2.3.4/32)"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for static website"
  type        = string
  default     = "jr-website-craig-7842"
}
