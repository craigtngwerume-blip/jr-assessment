output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.web.public_ip
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.web.id
}

output "ebs_volume_id" {
  description = "EBS data volume ID"
  value       = aws_ebs_volume.data.id
}

output "availability_zone" {
  description = "AZ the instance is in"
  value       = aws_instance.web.availability_zone
}
