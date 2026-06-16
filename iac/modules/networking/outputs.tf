output "vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "List of default subnet IDs"
  value       = data.aws_subnets.default.ids
}

output "first_subnet_id" {
  description = "First available subnet ID"
  value       = data.aws_subnets.default.ids[0]
}

output "availability_zones" {
  description = "Available AZs in the region"
  value       = data.aws_availability_zones.available.names
}
