#!/bin/bash
# Run this on the EC2 instance to install scripts and set up cron
set -euo pipefail

# Copy scripts to /usr/local/bin
sudo cp setup_web.sh /usr/local/bin/setup_web.sh
sudo cp rotate_logs.sh /usr/local/bin/rotate_logs.sh
sudo chmod +x /usr/local/bin/setup_web.sh
sudo chmod +x /usr/local/bin/rotate_logs.sh

# Run setup_web.sh
sudo /usr/local/bin/setup_web.sh

# Install cron entry
(sudo crontab -l 2>/dev/null; echo "15 2 * * * /usr/local/bin/rotate_logs.sh >> /var/log/rotate_logs.log 2>&1") | sudo crontab -

echo "Crontab installed:"
sudo crontab -l

# Test rotate_logs.sh (creates a fake large log to trigger rotation)
echo "[TEST] Creating dummy 6MB log to test rotation..."
sudo dd if=/dev/zero of=/var/log/httpd/access_log bs=1M count=6 2>/dev/null
sudo /usr/local/bin/rotate_logs.sh
echo "[TEST] Archives created:"
ls -lh /var/log/httpd/access_log*.gz 2>/dev/null || echo "No archives yet"
