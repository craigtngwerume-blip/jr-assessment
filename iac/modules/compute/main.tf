# ── Compute Module ────────────────────────────────────────────────────────────
# Creates the Launch Template, EC2 instance, EBS data volume, and attachment.
# The Launch Template is reusable — the same config can launch additional
# instances via Console, CLI, or Auto Scaling Group.

data "aws_ami" "al2023" {
  owners      = ["137112412989"] # Amazon official account
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web" {
  name          = "jr-assessment-lt"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = filebase64("${path.module}/user_data.sh")

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.name}-web"
      Project = var.name
      Owner   = var.owner
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name    = "${var.name}-root-vol"
      Project = var.name
      Owner   = var.owner
    }
  }

  tags = {
    Name    = "jr-assessment-lt"
    Project = var.name
    Owner   = var.owner
  }
}

resource "aws_key_pair" "main" {
  key_name   = "github-actions-key"
  public_key = var.ec2_public_key
}

resource "aws_instance" "web" {
  subnet_id = var.subnet_id
  key_name  = aws_key_pair.main.key_name
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tags = {
    Name    = "${var.name}-web"
    Project = var.name
    Owner   = var.owner
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.web.availability_zone
  size              = 4
  type              = "gp3"

  tags = {
    Name    = "${var.name}-data-vol"
    Project = var.name
    Owner   = var.owner
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.web.id
}
