output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "public_ip" {
  description = "EC2 public IP address"
  value       = module.compute.public_ip
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = module.compute.launch_template_id
}

output "ebs_volume_id" {
  description = "EBS data volume ID"
  value       = module.compute.ebs_volume_id
}

output "s3_website_endpoint" {
  description = "S3 static website URL"
  value       = module.storage.website_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}

output "security_group_id" {
  description = "Web security group ID"
  value       = module.security.security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${module.compute.public_ip}"
}
