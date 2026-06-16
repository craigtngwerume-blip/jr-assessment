output "security_group_id" {
  description = "Web security group ID"
  value       = aws_security_group.web.id
}

output "key_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.main.key_name
}
