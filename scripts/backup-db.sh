#!/bin/bash
# PostgreSQL Backup Script

set -e

BACKUP_DIR="/backups"
RETENTION_DAYS=3
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql.gz"

echo "[$(date)] Starting backup of database: $DB_NAME..."

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Perform backup using pg_dump
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h "$DB_HOST" -U "$POSTGRES_USER" -d "$DB_NAME" | gzip > "$BACKUP_FILE"

echo "[$(date)] Backup completed: $BACKUP_FILE"

# Clean up old backups
echo "[$(date)] Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql.gz" -mtime +$RETENTION_DAYS -exec rm {} \;

echo "[$(date)] Backup process finished successfully."
