# Task F — Troubleshooting Findings

---

## Scenario 1 — Can't SSH to EC2

**Symptom:** Instance has a public IP but SSH times out or is refused.

**Root cause checklist (in order):**

1. **Security Group inbound rules** — confirm port 22 is open from your current IP. IPs change; run `curl checkip.amazonaws.com` and verify the SG allows that exact `/32`.
2. **Route table** — the subnet's route table must have a route `0.0.0.0/0 → igw-xxxxx` (Internet Gateway). Without it, the instance has no path out/in.
3. **Network ACL** — NACLs are stateless. Both inbound (port 22) and outbound (ephemeral ports 1024–65535) must be allowed.
4. **Instance state** — `aws ec2 describe-instances` — must be `running`, not `stopped` or `terminated`.
5. **Public IP** — confirm the instance has a public IP or Elastic IP assigned.
6. **Correct user** — Amazon Linux 2023 uses `ec2-user`, not `ubuntu` or `root`.
7. **Key pair** — the `.pem` used must match the key pair the instance was launched with. Permissions must be `chmod 400`.
8. **SSM alternative** — if SSH is blocked entirely, use `aws ssm start-session --target <instance-id>` (requires SSM agent running and IAM instance profile with `AmazonSSMManagedInstanceCore`).

**Fix:**
```bash
# Check and update SG
MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxx \
  --protocol tcp --port 22 \
  --cidr $MY_IP
```

---

## Scenario 2 — S3 Website Returns 403

**Symptom:** Visiting the S3 website endpoint returns `403 Forbidden`.

**Root causes:**

1. **Block Public Access still enabled** — even with a public bucket policy, BPA overrides it. All four BPA settings must be `false` for website hosting with a public policy.
2. **Bucket policy missing or wrong path** — policy `Resource` must end with `/*` (for objects), not just the bucket ARN.
3. **Object not uploaded** — `index.html` must exist in the bucket. An empty bucket returns 403/404.
4. **Wrong endpoint** — S3 website endpoint format: `http://<bucket>.s3-website.<region>.amazonaws.com` — not the REST API endpoint.

**Fix:**
```bash
# Disable Block Public Access
aws s3api put-public-access-block \
  --bucket jr-website-craig-7842 \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Re-apply bucket policy
aws s3api put-bucket-policy \
  --bucket jr-website-craig-7842 \
  --policy file://s3/bucket-policy.json
```

---

## Scenario 3 — EBS Grown But Filesystem Unchanged

**Symptom:** `lsblk` shows 8 GiB but `df -h` still shows 4 GiB.

**Root cause:** Resizing the EBS volume in AWS only grows the block device. The filesystem inside it must be explicitly told to use the new space.

**Fix:**

For XFS (`/data`):
```bash
sudo xfs_growfs /data
# XFS grows using the mount point, not the device
```

For ext4:
```bash
sudo resize2fs /dev/xvdf
# ext4 uses the device path; can be done online if mounted
```

**Verify:**
```bash
df -h /data    # now shows 8G
lsblk          # xvdf shows 8G
```

---

## Scenario 4 — Terraform Apply Fails: NoCredentialProviders / Wrong Region

**Symptom:** `Error: NoCredentialProviders` or resources created in the wrong region.

**Root causes:**

1. **No AWS credentials configured** — Terraform uses the same credential chain as the AWS CLI.
2. **Wrong region** — provider region variable not set or `AWS_DEFAULT_REGION` pointing elsewhere.

**Fix:**
```bash
# Option A — AWS CLI configure (persistent)
aws configure
# Enter: Access Key ID, Secret Access Key, Region (af-south-1), output format

# Option B — Environment variables (session-scoped)
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=af-south-1

# Verify
aws sts get-caller-identity

# Re-run Terraform safely
terraform plan   # preview changes first
terraform apply
```

**Safe re-run:** Terraform is idempotent — if apply was partially successful, re-running applies only what's missing. No manual cleanup needed.

---

## Scenario 5 — HTTP 502 on EC2 / httpd Inactive After Reboot

**Symptom:** Browser returns 502 or connection refused after instance reboot.

**Root cause:** `httpd` was started manually but not enabled for boot via `systemctl enable`. On reboot it doesn't start automatically.

**Fix:**
```bash
# SSH in
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>

# Check status
sudo systemctl status httpd

# Check logs
sudo journalctl -u httpd --since "10 minutes ago"
sudo tail -50 /var/log/httpd/error_log

# Enable on boot and start
sudo systemctl enable --now httpd

# Verify port 80 is listening
sudo ss -tlnp | grep :80

# Also verify SG allows port 80
aws ec2 describe-security-groups --group-ids sg-xxxx \
  --query 'SecurityGroups[].IpPermissions'
```

**Prevention:** Always use `systemctl enable --now httpd` (enables + starts in one command). The `--now` flag ensures it starts immediately AND on all future reboots.
