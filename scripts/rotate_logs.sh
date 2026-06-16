#!/bin/bash
# rotate_logs.sh — Rotate Apache logs when they exceed 5 MB
# Keeps 5 compressed archives, removes older ones.
# Cron: 15 2 * * * /usr/local/bin/rotate_logs.sh >> /var/log/rotate_logs.log 2>&1

set -euo pipefail

LOGDIR=/var/log/httpd
MAX_SIZE=$((5 * 1024 * 1024))   # 5 MB in bytes
MAX_ARCHIVES=5
LOGS=("access_log" "error_log")

echo "=== $(date '+%Y-%m-%d %H:%M:%S') rotate_logs.sh starting ==="

for f in "${LOGS[@]}"; do
  FILE="${LOGDIR}/${f}"

  # Skip if file doesn't exist
  if [[ ! -f "$FILE" ]]; then
    echo "[INFO] $FILE not found — skipping"
    continue
  fi

  SIZE=$(stat -c%s "$FILE")
  echo "[INFO] $FILE size: ${SIZE} bytes"

  if [[ "$SIZE" -gt "$MAX_SIZE" ]]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE="${FILE}.${TIMESTAMP}"

    echo "[INFO] Rotating $FILE -> ${ARCHIVE}.gz"

    # Move and compress
    mv "$FILE" "$ARCHIVE"
    gzip "$ARCHIVE"

    # Recreate empty log file with correct permissions
    touch "$FILE"
    chmod 640 "$FILE"
    chown root:adm "$FILE" 2>/dev/null || true

    # Signal Apache to reopen log files
    if systemctl is-active --quiet httpd; then
      kill -USR1 "$(cat /var/run/httpd/httpd.pid 2>/dev/null || echo 0)" 2>/dev/null || true
    fi

    echo "[INFO] Rotation complete: ${ARCHIVE}.gz"
  else
    echo "[INFO] $FILE below threshold — no rotation needed"
  fi

  # Prune old archives — keep only MAX_ARCHIVES most recent
  ARCHIVE_COUNT=$(ls -1t "${FILE}".*.gz 2>/dev/null | wc -l)
  if [[ "$ARCHIVE_COUNT" -gt "$MAX_ARCHIVES" ]]; then
    echo "[INFO] Pruning old archives (keeping $MAX_ARCHIVES)..."
    ls -1t "${FILE}".*.gz 2>/dev/null | tail -n "+$((MAX_ARCHIVES + 1))" | xargs -r rm -f
    echo "[INFO] Pruned $((ARCHIVE_COUNT - MAX_ARCHIVES)) old archive(s)"
  fi
done

echo "=== $(date '+%Y-%m-%d %H:%M:%S') rotate_logs.sh completed ==="
