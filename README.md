# Cloudflare DNS Dynamic Updater

This tool updates a DNS record on Cloudflare to your machine's current public IPv4 address. It is useful if your ISP assigns you a dynamic IP and you want your domain to always point to your current IP.

---

## Features

- Automatically fetches your current public IP
- Checks the Cloudflare DNS record IP
- Updates the DNS record if your IP has changed
- Supports scheduled automatic updates via cron

---

## Requirements

- Linux-based system
- `curl` (for HTTP requests)
- `jq` (for JSON parsing)
- Cloudflare API Token with DNS edit permissions

---

## Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/TheNebulo/Cloudfare-DDNS-Updater.git
   cd Cloudfare-DDNS-Updater
   ```

2. Run the installer as root or with sudo (don't forget to apply permissions):

    ```bash
    chmod +x install.sh
    sudo ./install.sh
    ```    

3. The installer will:

    - Install curl and jq if not already installed
    - Copy the update script to /usr/local/bin/update_cf_dns.sh
    - Create the config file at /etc/cf_dns_update.conf
    - Prompt for your Cloudflare API token, zone ID, record ID, and DNS record name
    - Optionally set up a cron job to run the updater every 30 minutes

## Configuration

The configuration file is located at `/etc/cf_dns_update.conf`:

```bash
API_TOKEN="your_cloudflare_api_token"
ZONE_ID="your_zone_id"
RECORD_ID="your_record_id"
RECORD_NAME="example.yourdomain.com"
```

You can edit this file manually to change settings.

## How to find your Cloudflare details

### API Token

- Go to Cloudflare dashboard
- Profile > API Tokens > Create Token
- Create a token with Edit DNS permissions on your zone

### Zone ID

- Go to your domain dashboard on Cloudflare
- Found in the right sidebar under API

### DNS Record ID

Run this command, replacing placeholders with your info:

```bash
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records?name=YOUR_RECORD_NAME" \
-H "Authorization: Bearer YOUR_API_TOKEN" \
-H "Content-Type: application/json" | jq -r '.result[0].id'
```

## Usage

### How to run manually

```bash
sudo /usr/local/bin/update_cf_dns.sh
```

### Cron Job

If installed via install.sh and enabled, the script runs every 30 minutes and logs output to:
```bash
/var/log/cf_dns_update.log
```

### Troubleshooting

- Make sure the API token has DNS edit permissions.
- Check the log file /var/log/cf_dns_update.log for errors.
- Ensure curl and jq are installed.

## License

This project uses the [MIT License](https://choosealicense.com/licenses/mit/).