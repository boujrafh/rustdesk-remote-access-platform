#!/bin/bash
# RustDesk Backup Script
# Automated backup of RustDesk data, database, and configuration

set -e

# Configuration
BACKUP_DIR="/backup/rustdesk"
PROJECT_DIR="/opt/rustdesk-remote-access-platform"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info "Starting RustDesk backup..."

# Create backup directory
mkdir -p $BACKUP_DIR
cd $PROJECT_DIR

# Backup RustDesk data
print_info "Backing up RustDesk data..."
if [ -d "./data" ]; then
    tar -czf $BACKUP_DIR/rustdesk_data_$DATE.tar.gz -C . ./data
    print_info "Data backup completed: rustdesk_data_$DATE.tar.gz"
else
    print_warning "No data directory found, skipping..."
fi

# Backup database (if running)
if docker-compose ps | grep -q rustdesk-db; then
    print_info "Backing up PostgreSQL database..."
    docker-compose exec -T postgres pg_dump -U rustdesk_admin rustdesk | \
        gzip > $BACKUP_DIR/rustdesk_db_$DATE.sql.gz
    print_info "Database backup completed: rustdesk_db_$DATE.sql.gz"
else
    print_info "Database not running, skipping..."
fi

# Backup configuration
print_info "Backing up configuration files..."
cp .env $BACKUP_DIR/.env_$DATE
cp docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml

# Backup Nginx configuration
if [ -d "./nginx" ]; then
    tar -czf $BACKUP_DIR/nginx_config_$DATE.tar.gz -C . ./nginx
    print_info "Nginx config backup completed"
fi

# Backup certificates
if [ -d "./certs" ]; then
    tar -czf $BACKUP_DIR/certs_$DATE.tar.gz -C . ./certs
    print_info "Certificates backup completed"
fi

# Calculate backup size
TOTAL_SIZE=$(du -sh $BACKUP_DIR | cut -f1)

# Remove old backups
print_info "Removing backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name ".env_*" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "docker-compose_*" -mtime +$RETENTION_DAYS -delete

REMAINING=$(ls -1 $BACKUP_DIR | wc -l)

# Log backup
echo "$(date): Backup completed successfully. Total size: $TOTAL_SIZE, Files: $REMAINING" >> /var/log/rustdesk-backup.log

print_info "Backup completed successfully!"
echo "Location: $BACKUP_DIR"
echo "Total size: $TOTAL_SIZE"
echo "Remaining backups: $REMAINING"
