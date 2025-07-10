# Automated Backup and Rotation Script with Google Drive Integration

## 📌 Overview

This project automates the backup of a GitHub-hosted project (`ebs-volume-optimizer`) on an EC2 instance. It:
- Creates timestamped `.zip` backups
- Uploads them to Google Drive using `rclone`
- Applies a rotational retention policy (daily, weekly, monthly)
- Sends a webhook notification upon successful backup

---

##  Installation & Setup

### 1. Clone GitHub Project
```bash
git clone https://github.com/SaloniPawar-59/ebs-volume-optimizer.git
```

### 2. Install Required Tools
```bash
sudo yum install zip curl -y
curl https://rclone.org/install.sh | sudo bash
```

### 3. Configure rclone with Google Drive
```bash
rclone config
# Choose 'n' → name: gdrive → type: 22 (Google Drive) → follow prompts
```

---

## How to Run the Script

```bash
chmod +x backup_script.sh
./backup_script.sh
```
---

##  Retention Policy

The script keeps:
- Last 7 daily backups
- Last 4 weekly (Sundays)
- Last 3 monthly (first of each month)

Retention settings can be customized in:
- The script variables
- Or `.env` file (recommended for separation of config)

---

##  Example of Webhook Payload

A POST request is sent to the webhook on successful backup:
```json
{
  "project": "EBSVolumeOptimizer",
  "date": "20250710_170558",
  "test": "BackupSuccessful"
}

Generated using:
```bash
curl -X POST -H "Content-Type: application/json" \
-d '{"project": "EBSVolumeOptimizer", "date": "BackupDate", "test": "BackupSuccessful"}' \
https://webhook.site/your-unique-url
```

---

##  Security Considerations

- Google Drive is accessed using `rclone`, which stores OAuth credentials in `~/.config/rclone/rclone.conf` (secure this file).
- Backups may contain sensitive code/data — limit read/write access to your EC2 home directory.

---

##  Output

Backups will be stored like:
```
~/backups/EBSVolumeOptimizer/2025/07/10/EBSVolumeOptimizer_20250710_153010.zip
```

Log file:
```
~/backup.log
```

Webhook can be tested at: [https://webhook.site](https://webhook.site)

---

## Scheduling

Use `cron` to automate daily backups:
```bash
0 2 * * * /home/ec2-user/backup_script.sh >> /home/ec2-user/cron.log 2>&1
```

---

