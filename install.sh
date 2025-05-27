#!/bin/bash
set -e

CONFIG_FILE="/etc/cf_dns_update.conf"
SCRIPT_NAME="update_cf_dns.sh"
INSTALL_PATH="/usr/local/bin/$SCRIPT_NAME"

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or with sudo"
  exit 1
fi

echo "Installing dependencies..."

if ! command -v curl &> /dev/null; then
  echo "Installing curl..."
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y curl
  elif command -v yum &> /dev/null; then
    yum install -y curl
  else
    echo "Please install curl manually."
    exit 1
  fi
else
  echo "curl found"
fi

if ! command -v jq &> /dev/null; then
  echo "Installing jq..."
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y jq
  elif command -v yum &> /dev/null; then
    yum install -y jq
  else
    echo "Please install jq manually."
    exit 1
  fi
else
  echo "jq found"
fi

echo "Copying script to $INSTALL_PATH"
cp "$SCRIPT_NAME" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "Creating config file at $CONFIG_FILE"
if [[ -f "$CONFIG_FILE" ]]; then
  echo "Config file already exists at $CONFIG_FILE, backing up to ${CONFIG_FILE}.bak"
  mv "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

echo "Please enter your Cloudflare details:"

read -rp "Cloudflare API Token (with DNS edit permission): " API_TOKEN
read -rp "Cloudflare Zone ID: " ZONE_ID
read -rp "Cloudflare DNS Record ID: " RECORD_ID
read -rp "DNS Record Name (e.g. example.yourdomain.com): " RECORD_NAME

cat <<EOF > "$CONFIG_FILE"
# Cloudflare DNS Updater Configuration
API_TOKEN="$API_TOKEN"
ZONE_ID="$ZONE_ID"
RECORD_ID="$RECORD_ID"
RECORD_NAME="$RECORD_NAME"
EOF

echo "Config file written."

read -rp "Do you want to set up a cron job to run this script every 30 minutes? (y/n) " yn
if [[ $yn =~ ^[Yy]$ ]]; then
  (crontab -l 2>/dev/null; echo "*/30 * * * * $INSTALL_PATH >> /var/log/cf_dns_update.log 2>&1") | crontab -
  echo "Cron job installed."
else
  echo "Cron job setup skipped."
fi

echo "Installation complete."