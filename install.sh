#!/bin/bash
set -e

CONFIG_FILE="/etc/cf_dns_update.conf"
SCRIPT_NAME="update_cf_dns.sh"
INSTALL_PATH="/usr/local/bin/$SCRIPT_NAME"

# Ensure script is executable (only when run via ./install.sh)
if [[ ! -x "$0" ]]; then
  echo "Making the install script executable..."
  chmod +x "$0"
fi

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or with sudo:"
  echo "sudo $0"
  exit 1
fi

echo "Installing dependencies..."

install_package() {
  local pkg=$1
  if ! command -v "$pkg" &> /dev/null; then
    echo "Installing $pkg..."
    if command -v apt-get &> /dev/null; then
      apt-get update -qq
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg"
    elif command -v yum &> /dev/null; then
      yum install -y -q "$pkg"
    else
      echo "Unsupported package manager. Please install $pkg manually."
      exit 1
    fi
  else
    echo "$pkg is already installed."
  fi
}

install_package curl
install_package jq

echo "Copying script to $INSTALL_PATH"
cp "$SCRIPT_NAME" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "Setting up configuration file at $CONFIG_FILE"
if [[ -f "$CONFIG_FILE" ]]; then
  echo "Backing up existing config to ${CONFIG_FILE}.bak"
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

echo "Configuration saved."

read -rp "Do you want to set up a cron job to run this script every 30 minutes? (y/n) " yn
if [[ $yn =~ ^[Yy]$ ]]; then
  # Add cron job if not already present
  CRON_JOB="*/30 * * * * $INSTALL_PATH >> /var/log/cf_dns_update.log 2>&1"
  if ! crontab -l 2>/dev/null | grep -Fq "$INSTALL_PATH"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job installed."
  else
    echo "Cron job already exists."
  fi
else
  echo "Skipping cron job setup."
fi

echo "Installation complete."
echo "Run the updater manually with:"
echo "  sudo $INSTALL_PATH"
echo "Or let the cron job run it automatically."