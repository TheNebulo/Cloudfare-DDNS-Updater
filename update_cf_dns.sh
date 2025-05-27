#!/bin/bash
set -e

# Load config file
CONFIG_FILE="/etc/cf_dns_update.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file $CONFIG_FILE not found. Please run the install script first."
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [[ -z "$API_TOKEN" || -z "$ZONE_ID" || -z "$RECORD_ID" || -z "$RECORD_NAME" ]]; then
  echo "One or more required configuration variables are empty in $CONFIG_FILE"
  exit 1
fi

CF_API="https://api.cloudflare.com/client/v4"

CURRENT_IP=$(curl -s https://api.ipify.org)
if [[ -z "$CURRENT_IP" ]]; then
  echo "Failed to get public IP"
  exit 1
fi

RECORD_JSON=$(curl -s -X GET "$CF_API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json")

RECORD_IP=$(echo "$RECORD_JSON" | jq -r '.result.content')

if [[ "$RECORD_IP" == "null" || -z "$RECORD_IP" ]]; then
  echo "Failed to get current DNS record IP from Cloudflare"
  exit 1
fi

if [[ "$CURRENT_IP" == "$RECORD_IP" ]]; then
  echo "IP unchanged ($CURRENT_IP), no update needed."
  exit 0
else
  echo "IP changed from $RECORD_IP to $CURRENT_IP, updating record..."
fi

UPDATE_JSON=$(jq -n --arg type "A" --arg name "$RECORD_NAME" --arg content "$CURRENT_IP" \
  '{type: $type, name: $name, content: $content, ttl: 1, proxied: false}')

RESPONSE=$(curl -s -X PUT "$CF_API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$UPDATE_JSON")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [[ "$SUCCESS" == "true" ]]; then
  echo "DNS record updated successfully."
else
  echo "Failed to update DNS record:"
  echo "$RESPONSE" | jq '.errors'
  exit 1
fi