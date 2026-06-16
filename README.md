# Junior/L1 Cloud Engineer Technical Assessment — Submission
**Candidate:** Craig  
**Region:** af-south-1 (Africa — Cape Town)  
**IaC tool:** Terraform >= 1.6  

---

## Repository Structure

```
jr-assessment/
├── ec2/              # Task A — EC2 commands and connection proof
├── s3/               # Task B — Bucket policy and commands
├── ebs/              # Task C — EBS attach/extend commands
├── iac/              # Task D — Terraform code (main.tf, variables.tf, outputs.tf)
├── scripts/          # Task E — setup_web.sh, rotate_logs.sh, crontab
├── troubleshooting/  # Task F — findings.md
└── README.md         # This file
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| AWS CLI | v2 |
| Terraform | >= 1.6 |
| Git | any |
| bash | any |
| SSH client | any |

---

## Environment Setup

### 1. AWS Credentials
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=af-south-1

# Verify
aws sts get-caller-identity
```

### 2. SSH Key Pair
```bash
# Generate if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Terraform reads ~/.ssh/id_rsa.pub automatically
```

### 3. Get your public IP
```bash
curl -s https://checkip.amazonaws.com
# e.g. 41.220.100.5 → use 41.220.100.5/32 as my_ip
```

### 4. Configure Terraform variables
```bash
cd iac/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set my_ip to your public IP/32
```

---

## Deploy Everything
```bash
cd iac/
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Terraform creates:
- Security Group (SSH from your IP, HTTP public)
- SSH Key Pair
- Launch Template (`jr-assessment-lt`)
- EC2 Instance (Amazon Linux 2023, t3.micro, 10 GiB gp3)
- EBS data volume (4 GiB gp3, attached as /dev/xvdf)
- S3 static website bucket

---

## Post-Deploy Steps

### SSH and verify HTTP
```bash
# Get outputs
terraform output

# SSH in
ssh -i ~/.ssh/id_rsa ec2-user@$(terraform output -raw public_ip)

# HTTP check (from local machine)
curl http://$(terraform output -raw public_ip)/
```

### EBS mount (run inside the instance)
```bash
sudo mkfs.xfs /dev/xvdf
sudo mkdir -p /data
sudo mount /dev/xvdf /data
UUID=$(sudo blkid -s UUID -o value /dev/xvdf)
echo "UUID=${UUID}  /data  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
df -h /data
```

### Install scripts and cron
```bash
# Copy scripts to instance
scp -i ~/.ssh/id_rsa scripts/setup_web.sh scripts/rotate_logs.sh \
  ec2-user@$(terraform output -raw public_ip):~/

# SSH in and install
ssh -i ~/.ssh/id_rsa ec2-user@$(terraform output -raw public_ip)
chmod +x setup_web.sh rotate_logs.sh
sudo cp setup_web.sh rotate_logs.sh /usr/local/bin/
sudo /usr/local/bin/setup_web.sh
(sudo crontab -l 2>/dev/null; echo "15 2 * * * /usr/local/bin/rotate_logs.sh >> /var/log/rotate_logs.log 2>&1") | sudo crontab -
sudo crontab -l
```

### Grow EBS volume to 8 GiB
```bash
# From local machine
aws ec2 modify-volume \
  --volume-id $(terraform output -raw ebs_volume_id) \
  --size 8

# Then on the instance
sudo xfs_growfs /data
df -h /data
```

---

## Key Design Decisions

### AMI — Amazon Linux 2023
AL2023 is the current AWS-maintained Linux distribution. It uses `dnf`/`yum`, has SELinux enforcing by default, and receives long-term support. Preferred over AL2 (approaching EOL) and Ubuntu (different package ecosystem from AWS tooling).

### Security Group — SSH restricted to my IP
SSH (port 22) is restricted to a single `/32` CIDR. This is the minimum privilege needed for direct SSH. In production I would remove SSH entirely and use SSM Session Manager, which requires no open inbound ports.

### Launch Template over plain aws_instance
The Launch Template (`jr-assessment-lt`) is reusable — you can launch additional instances with identical config from the Console, CLI, or Auto Scaling Group without re-specifying all parameters. This satisfies the "reusable method" requirement.

### EBS — UUID in /etc/fstab with nofail
Device names (`/dev/xvdf`) are not guaranteed stable across reboots or instance types. UUID is stable and device-independent. `nofail` prevents a boot hang if the volume is temporarily detached.

### S3 — Public bucket policy acceptable for demo
The bucket only contains a static "Hello World" page with no sensitive data. In production: use CloudFront with Origin Access Control (OAC), keep Block Public Access fully enabled on the bucket, and serve entirely through CloudFront.

### Terraform structure — variables/outputs separated
`variables.tf`, `main.tf`, and `outputs.tf` are kept separate for readability and to follow community conventions. Sensitive values (`my_ip`) are in `terraform.tfvars` which is gitignored.

---

## Acceptance Check Commands

```bash
# Tag audit
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=jr-assessment

# EC2 describe
aws ec2 describe-instances \
  --filters Name=tag:Project,Values=jr-assessment \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress,AZ:Placement.AvailabilityZone}' \
  --output table

# HTTP check
curl -s http://$(terraform output -raw public_ip)/ | grep -E "Instance ID|Hello"

# S3 website
curl http://jr-website-craig-7842.s3-website.af-south-1.amazonaws.com/
```

---

## Cleanup
```bash
# Destroy all Terraform-managed resources
cd iac/
terraform destroy

# Verify nothing left
aws ec2 describe-instances \
  --filters Name=tag:Project,Values=jr-assessment \
            Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].InstanceId'

# S3 bucket is destroyed by terraform destroy (force_destroy=true)
```

---

## Security Hygiene Notes
- `terraform.tfvars` and `*.tfstate` are in `.gitignore` — credentials and state never committed
- SSH key is generated locally, public key only is uploaded to AWS
- SG restricts SSH to a single IP — no `0.0.0.0/0` on port 22
- Scripts use `set -euo pipefail` — fail fast on errors
- IMDSv2 token used in user data (not IMDSv1) for metadata access
