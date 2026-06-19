variable "name" {
  description = "Project name prefix"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "my_ip" {
  default     = "172.24.192.1/32"
  description = "Your public IP for SSH access (e.g. 1.2.3.4/32)"
  type        = string
}

variable "ec2_public_key" {
  description = "SSH public key for EC2"
  type        = string
  sensitive   = true
}
