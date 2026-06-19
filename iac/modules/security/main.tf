# ── Security Module ───────────────────────────────────────────────────────────
# Manages the security group and SSH key pair.
# SSH is restricted to a single /32 CIDR (your IP only).
# HTTP is open to the internet for the web server.

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Allow SSH from my IP only and HTTP from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP only — least privilege"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.name}-web-sg"
    Project = var.name
    Owner   = var.owner
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.name}-key"
  public_key = var.ec2_public_key #file("~/.ssh/id_rsa.pub")

  tags = {
    Name    = "${var.name}-key"
    Project = var.name
    Owner   = var.owner
  }
}
