# ── Networking Module ─────────────────────────────────────────────────────────
# Discovers the default VPC, subnets, and availability zones.
# In a production setup this would create a custom VPC, public/private subnets,
# NAT gateway, and route tables instead of using defaults.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
