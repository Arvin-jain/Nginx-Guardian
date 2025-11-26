# Nginx Guardian

Automated IP Blocking System for Nginx

An intelligent bash script that analyzes nginx access logs and automatically blocks suspicious IP addresses based on error rates and request patterns.

---

## Features

- Automatic threat detection - Identifies suspicious IPs based on 404 errors and excessive requests
- Detailed reporting - Generates comprehensive security reports with statistics
- Safe operation - Creates backups before making changes
- Flexible configuration - Customizable thresholds via command-line arguments
- Easy automation - Perfect for cron jobs
- Color-coded output - Clear visual feedback during operation

---

## Table of Contents

- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Command-Line Arguments](#command-line-arguments)
- [Usage Examples](#usage-examples)
- [Automation with Cron](#automation-with-cron)
- [Important Notes](#important-notes)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

---

## How It Works

### Simplified Process Flow

1. **Initial Setup & Validation**
   - Sets configuration defaults (log location, thresholds for banning)
   - Checks if running as root (required for nginx config changes)
   - Parses any command-line options to override defaults
   - Verifies the nginx access log file exists

2. **Log Analysis (The Core)**
   - Uses `awk` to scan through the entire nginx access log
   - Counts total requests per IP address
   - Counts 404 errors (page not found) per IP
   - Counts 403/401 errors (forbidden/unauthorized) per IP
   - Identifies "suspicious" IPs that exceed thresholds:
     - 10+ 404 errors, OR
     - 50+ total requests

3. **Creating the Ban List**
   - For each suspicious IP found:
     - Adds a `deny [IP];` line to the nginx blocking configuration file
     - Records details in a human-readable report
     - Displays the IP and its statistics on screen

4. **Generating Reports**
   - Creates a detailed report file showing:
     - Which IPs were blocked
     - Their request statistics (total requests, error counts)
     - Summary of actions taken
     - Timestamp of the analysis

5. **Applying Changes**
   - Backs up the existing nginx config before making changes
   - Offers to automatically reload nginx to apply the new blocks
   - If declined, provides manual reload instructions

6. **Cleanup**
   - Removes temporary files
   - Displays the full report
   - Shows completion message

**In essence:** It's an automated bouncer that reads your nginx logs, identifies IPs behaving suspiciously (too many errors or excessive requests), and blocks them from accessing your server.

---

## Prerequisites

- Root or sudo access
- Nginx web server installed and running
- Bash shell (standard on most Linux systems)
- Access to nginx log files

---

## Installation

### Step 1: Download and Set Permissions

```bash
# Save the script
sudo nano /usr/local/bin/nginx_guardian.sh

# Paste the script content and save (Ctrl+X, Y, Enter)

# Make it executable
sudo chmod +x /usr/local/bin/nginx_guardian.sh
```

### Step 2: Create Required Directories

```bash
# Ensure nginx conf.d directory exists
sudo mkdir -p /etc/nginx/conf.d

# Ensure log directory is accessible
sudo ls -la /var/log/nginx/access.log
```

### Step 3: Configure Nginx to Load Blocked IPs

Edit your main nginx configuration:

```bash
sudo nano /etc/nginx/nginx.conf
```

Add this line inside the `http` block:

```nginx
http {
    # ... other configurations ...
    
    include /etc/nginx/conf.d/blocked_ips.conf;
    
    # ... rest of configuration ...
}
```

### Step 4: Test Nginx Configuration

```bash
sudo nginx -t
```

If successful, reload nginx:

```bash
sudo systemctl reload nginx
```

---

## Usage

### Basic Usage (Default Settings)

```bash
sudo /usr/local/bin/nginx_guardian.sh
```

This uses default thresholds:
- Blocks IPs with 10+ 404 errors
- Blocks IPs with 50+ total requests

### Advanced Usage with Arguments

```bash
sudo /usr/local/bin/nginx_guardian.sh [OPTIONS]
```

---

## Command-Line Arguments

| Argument | Description | Default Value | Example |
|----------|-------------|---------------|---------|
| `-l` | Log file path - Specify custom nginx access log location | `/var/log/nginx/access.log` | `-l /var/log/nginx/custom.log` |
| `-f` | 404 threshold - Minimum 404 errors to trigger a ban | `10` | `-f 20` |
| `-t` | Total requests threshold - Minimum total requests to trigger a ban | `50` | `-t 100` |
| `-c` | Config file path - Where to save the nginx blocking rules | `/etc/nginx/conf.d/blocked_ips.conf` | `-c /etc/nginx/custom_blocks.conf` |
| `-r` | Report file path - Where to save the analysis report | `/var/log/nginx_guardian_report.txt` | `-r /home/user/report.txt` |

---

## Usage Examples

### Example 1: More Aggressive Blocking

Block IPs with just 5 404 errors or 25 total requests:

```bash
sudo ./nginx_guardian.sh -f 5 -t 25
```

### Example 2: Less Aggressive (Production-Safe)

Only block very suspicious activity:

```bash
sudo ./nginx_guardian.sh -f 50 -t 200
```

### Example 3: Custom Log Location

Analyze a specific virtual host log:

```bash
sudo ./nginx_guardian.sh -l /var/log/nginx/mysite_access.log
```

### Example 4: Complete Custom Setup

All custom parameters:

```bash
sudo ./nginx_guardian.sh \
  -l /var/log/nginx/production.log \
  -f 15 \
  -t 75 \
  -c /etc/nginx/conf.d/custom_blocks.conf \
  -r /home/admin/security_report.txt
```

### Example 5: Testing Without Affecting Live Site

Use a custom config file that isn't included in nginx:

```bash
sudo ./nginx_guardian.sh \
  -c /tmp/test_blocks.conf \
  -r /tmp/test_report.txt
```

Then review `/tmp/test_blocks.conf` before applying to production.

---

## Automation with Cron

### Run Every Hour

```bash
sudo crontab -e
```

Add this line:

```cron
0 * * * * /usr/local/bin/nginx_guardian.sh -f 15 -t 100 >> /var/log/nginx_guardian_cron.log 2>&1
```

### Run Daily at 3 AM

```cron
0 3 * * * /usr/local/bin/nginx_guardian.sh >> /var/log/nginx_guardian_cron.log 2>&1
```

### Run Every 15 Minutes (Aggressive)

```cron
*/15 * * * * /usr/local/bin/nginx_guardian.sh -f 5 -t 25 >> /var/log/nginx_guardian_cron.log 2>&1
```

---

## Important Notes

### Before First Run

1. Review your current logs to understand normal traffic patterns
2. Test with conservative thresholds first (high numbers)
3. Keep a backup of your nginx configuration
4. Document your IP if accessing remotely to avoid locking yourself out

### Monitoring

Check the report regularly:

```bash
cat /var/log/nginx_guardian_report.txt
```

View currently blocked IPs:

```bash
cat /etc/nginx/conf.d/blocked_ips.conf
```

### Unblocking IPs

To unblock an IP, edit the config:

```bash
sudo nano /etc/nginx/conf.d/blocked_ips.conf
```

Remove the line with the IP, save, then reload:

```bash
sudo nginx -s reload
```

### Best Practices

- **Start conservative**: Use high thresholds initially
- **Monitor for false positives**: Legitimate users might trigger blocks
- **Whitelist important IPs**: Add your monitoring services, office IPs to nginx allow list
- **Review reports weekly**: Adjust thresholds based on patterns
- **Keep logs**: The script creates backups with timestamps

---

## Troubleshooting

### Script won't run

```bash
# Check permissions
ls -l /usr/local/bin/nginx_guardian.sh

# Should show: -rwxr-xr-x
```

### Nginx won't reload

```bash
# Test configuration
sudo nginx -t

# Check for syntax errors in blocked_ips.conf
```

### No IPs being blocked

- Lower the thresholds with `-f` and `-t`
- Verify log file path is correct
- Check if log file has recent entries

### Accidentally blocked yourself

Access server via console/alternative method and:

```bash
sudo rm /etc/nginx/conf.d/blocked_ips.conf
sudo nginx -s reload
```

---

## Security Considerations

- This script does not permanently ban IPs across log rotations
- Consider implementing fail2ban for persistent blocking
- Regularly review blocked IPs for false positives
- Consider geo-blocking for specific attack patterns
- Keep nginx and system updated

---

## License

This project is provided as-is for educational and practical use.

---

## Contributing

Contributions, issues, and feature requests are welcome.

---

## Support

For issues or questions, please review the troubleshooting section or check your nginx error logs for additional details.
