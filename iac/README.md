# IaC — Terraform

## What this creates
- Security Group (SSH from your IP, HTTP from anywhere)
- SSH Key Pair (from ~/.ssh/id_rsa.pub)
- Launch Template (`jr-assessment-lt`) — Amazon Linux 2023, t3.micro, 10 GiB gp3
- EC2 Instance (from Launch Template)
- EBS data volume (4 GiB gp3) attached as /dev/xvdf
- S3 bucket with static website hosting

## Prerequisites
- AWS CLI v2 configured (`aws configure`)
- Terraform >= 1.6
- SSH key pair at `~/.ssh/id_rsa.pub`

## Environment variables
```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=af-south-1
```

## How to run
```bash
# 1. Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set my_ip to your public IP

# 2. Get your public IP
curl -s https://checkip.amazonaws.com
# Append /32 to the result e.g. 41.220.100.5/32

# 3. Init, plan, apply
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# 4. View outputs
terraform output

# 5. Destroy when done
terraform destroy
```

## Idempotency
Running `terraform apply` a second time results in "No changes" — all resources are already in the desired state.
