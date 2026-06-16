#!/bin/bash
set -euxo pipefail

# Update system packages
yum update -y

# Install Apache and jq (for metadata queries)
yum install -y httpd jq

# Enable and start Apache
systemctl enable --now httpd

# Fetch instance metadata using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")

HOSTNAME=$(hostname -f)

# Write index page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>jr-assessment Web Server</title></head>
<body>
  <h1>Hello from ${HOSTNAME}</h1>
  <p><strong>Instance ID:</strong> ${INSTANCE_ID}</p>
  <p><strong>Hostname:</strong> ${HOSTNAME}</p>
  <p><strong>Project:</strong> jr-assessment</p>
  <p><strong>Owner:</strong> craig</p>
</body>
</html>
EOF

# Ensure Apache is running
systemctl status httpd
