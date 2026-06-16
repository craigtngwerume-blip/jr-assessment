# Task B — S3 Static Website Commands

## Manual CLI steps (handled by Terraform automatically)

```bash
# Create bucket
aws s3api create-bucket \
  --bucket jr-website-craig-7842 \
  --region af-south-1 \
  --create-bucket-configuration LocationConstraint=af-south-1

# Enable static website hosting
aws s3api put-bucket-website \
  --bucket jr-website-craig-7842 \
  --website-configuration '{
    "IndexDocument": {"Suffix": "index.html"},
    "ErrorDocument": {"Key": "error.html"}
  }'

# Disable Block Public Access (required before applying public bucket policy)
aws s3api put-public-access-block \
  --bucket jr-website-craig-7842 \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Apply public read bucket policy
aws s3api put-bucket-policy \
  --bucket jr-website-craig-7842 \
  --policy file://bucket-policy.json

# Upload index.html
aws s3 cp index.html s3://jr-website-craig-7842/index.html \
  --content-type text/html

# Verify website endpoint
curl http://jr-website-craig-7842.s3-website.af-south-1.amazonaws.com/
```

## Why public bucket policy is acceptable for this demo
This is a demo with no sensitive data — the only content is a static "Hello World" page.

## How to harden in production
- **CloudFront + OAC (Origin Access Control):** Keep the bucket fully private, serve via CloudFront with OAC. No public bucket policy needed.
- **Block Public Access ON:** Re-enable all BPA settings once OAC is configured.
- **WAF:** Attach AWS WAF to CloudFront for rate limiting and geo-blocking.
- **Bucket versioning + access logging:** Track object changes and access patterns.
