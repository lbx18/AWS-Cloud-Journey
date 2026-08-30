#!/bin/bash 
# Simple backup script - pulls /data from the EC2 instance to local machine.

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S) 
BACKUP_DIR="./backups/backup_$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

rsync -avz week2lab:/home/ec2-user/data  "$BACKUP_DIR"

echo "Backup completed: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
