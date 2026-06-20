variable "name" {
  description = "Project name prefix"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
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

variable "security_group_id" {
  description = "Security group ID to attach to the instance"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

/*variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}
*/
variable "ec2_public_key" {
  description = "SSH public key for EC2"
  type        = string
  sensitive   = true
}

variable "public_subnet_id" {
  description = "Public subnet for EC2 instances"
  type        = string
}

/*variable "private_subnet_id" {
  type = string
}
*/
