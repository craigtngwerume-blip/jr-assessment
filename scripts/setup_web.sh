#!/bin/bash
# setup_web.sh — Install and configure Apache web server
# Safe to re-run (idempotent). Logs to /var/log/setup_web.log.
# Usage: sudo bash setup_web.sh

set -euo pipefail

LOG=/var/log/setup_web.log
exec > >(tee -a "$LOG") 2>&1

echo "=== $(date '+%Y-%m-%d %H:%M:%S') setup_web.sh starting ==="

# ── Install httpd if not already installed ────────────────────────────────────
if rpm -q httpd &>/dev/null; then
  echo "[INFO] httpd already installed — skipping install"
else
  echo "[INFO] Installing httpd..."
  yum install -y httpd
  echo "[INFO] httpd installed"
fi

# ── Enable and start httpd ────────────────────────────────────────────────────
echo "[INFO] Enabling httpd on boot..."
systemctl enable httpd

if systemctl is-active --quiet httpd; then
  echo "[INFO] httpd already running"
else
  echo "[INFO] Starting httpd..."
  systemctl start httpd
fi

# ── Deploy index.html ─────────────────────────────────────────────────────────
INDEX=/var/www/html/index.html

echo "[INFO] Writing index.html..."
cat > "$INDEX" <<'HTML'
<!DOCTYPE html>
<html>
<head><title>Ola World</title></head>
<body>
  <h1>Ola World</h1>
  <p>Server: HOSTNAME_PLACEHOLDER</p>
</body>
</html>
HTML

# Replace placeholder with actual hostname
sed -i "s/HOSTNAME_PLACEHOLDER/$(hostname -f)/" "$INDEX"

echo "[INFO] index.html written to $INDEX"

# ── Verify httpd is running ───────────────────────────────────────────────────
if ! systemctl is-active --quiet httpd; then
  echo "[ERROR] httpd failed to start" >&2
  systemctl status httpd >&2
  exit 1
fi

echo "[INFO] httpd is running"
echo "=== $(date '+%Y-%m-%d %H:%M:%S') setup_web.sh completed successfully ==="
