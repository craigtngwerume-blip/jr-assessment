terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-state-craign-2026-296274010522-af-south-1-an"
    key     = "ec2/terraform.tfstate"
    region  = "af-south-1"
    encrypt = true
  }
}


provider "aws" {
  region = var.region
}

# ── Networking ────────────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"
  region = var.region
}

# ── Security ──────────────────────────────────────────────────────────────────
module "security" {
  source         = "./modules/security"
  name           = var.name
  owner          = var.owner
  vpc_id         = module.networking.vpc_id
  my_ip          = var.my_ip
  ec2_public_key = var.ec2_public_key
}

# ── Compute ───────────────────────────────────────────────────────────────────
module "compute" {
  source            = "./modules/compute"
  name              = var.name
  owner             = var.owner
  instance_type     = var.instance_type
  root_volume_size  = var.root_volume_size
  security_group_id = module.security.security_group_id
  key_name          = module.security.key_name
  ec2_public_key    = var.ec2_public_key
  public_subnet_id  = module.networking.public_subnet_id
}

# ── Storage ───────────────────────────────────────────────────────────────────
module "storage" {
  source      = "./modules/storage"
  name        = var.name
  owner       = var.owner
  bucket_name = var.bucket_name
  region      = var.region
}
