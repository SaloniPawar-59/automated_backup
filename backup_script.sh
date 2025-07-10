#!/bin/bash

# === CONFIG ===
PROJECT_NAME="EBSVolumeOptimizer"
SRC_DIR="$HOME/ebs-volume-optimizer"
BACKUP_DIR="$HOME/backups/$PROJECT_NAME"
DATE=$(date +"%Y/%m/%d")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ZIP_NAME="${PROJECT_NAME}_${TIMESTAMP}.zip"
LOG_FILE="$HOME/backup.log"
REMOTE_NAME="gdrive"
REMOTE_FOLDER="ProjectBackups"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
NOTIFY=true
WEBHOOK_URL="https://webhook.site/9944db75-7185-4a04-986d-157bc12a4883"

# === CREATE ZIP ===
mkdir -p "$BACKUP_DIR/$DATE"
cd "$SRC_DIR" || exit 1
zip -r "$BACKUP_DIR/$DATE/$ZIP_NAME" . >> "$LOG_FILE" 2>&1

# === UPLOAD TO GOOGLE DRIVE ===
rclone copy "$BACKUP_DIR/$DATE/$ZIP_NAME" "$REMOTE_NAME:$REMOTE_FOLDER" >> "$LOG_FILE" 2>&1
UPLOAD_STATUS=$?

# === ROTATION ===
rotate_backups() {
    find "$BACKUP_DIR" -type f -name "*.zip" | while read -r file; do
        file_date=$(basename "$file" | grep -oP '\d{8}_\d{6}' | cut -c1-8)
        file_day=$(date -d "$file_date" +%u)
        file_month=$(date -d "$file_date" +%m)
        today=$(date +%Y%m%d)

        # Daily - Keep last 7
        if [ "$file_day" -ne 7 ]; then
            older=$(find "$BACKUP_DIR" -type f -name "*.zip" -printf "%T@ %p\n" | sort -n | head -n -"$DAILY_KEEP" | awk '{print $2}')
            for old in $older; do
                rm -f "$old" && echo "Deleted daily: $old" >> "$LOG_FILE"
            done
        fi

        # Weekly (Sundays) - Keep last 4
        if [ "$file_day" -eq 7 ]; then
            older=$(find "$BACKUP_DIR" -type f -name "*.zip" -printf "%T@ %p\n" | grep Sunday | sort -n | head -n -"$WEEKLY_KEEP" | awk '{print $2}')
            for old in $older; do
                rm -f "$old" && echo "Deleted weekly: $old" >> "$LOG_FILE"
            done
        fi

        # Monthly (first day of month) - Keep last 3
        dom=$(date -d "$file_date" +%d)
        if [ "$dom" == "01" ]; then
            older=$(find "$BACKUP_DIR" -type f -name "*_01*.zip" | sort | head -n -"$MONTHLY_KEEP")
            for old in $older; do
                rm -f "$old" && echo "Deleted monthly: $old" >> "$LOG_FILE"
            done
        fi
    done
}

rotate_backups

# === SEND NOTIFICATION ===
if [ "$UPLOAD_STATUS" -eq 0 ]; then
    echo "Backup Successful: $ZIP_NAME at $(date)" >> "$LOG_FILE"
    if [ "$NOTIFY" = true ]; then
        curl -X POST -H "Content-Type: application/json" \
        -d "{\"project\": \"$PROJECT_NAME\", \"date\": \"$TIMESTAMP\", \"test\": \"BackupSuccessful\"}" \
        "$WEBHOOK_URL"
    fi
else
    echo "Upload failed for $ZIP_NAME at $(date)" >> "$LOG_FILE"
fi
