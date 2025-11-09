#!/bin/bash
# RustDesk Restore Script
# Restore RustDesk from backup

set -e

BACKUP_DIR="/backup/rustdesk"
PROJECT_DIR="/opt/rustdesk-remote-access-platform"

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

if [ ! -d "$BACKUP_DIR" ]; then
    print_error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

cd $PROJECT_DIR

# List available backups
echo "Available backups:"
ls -lh $BACKUP_DIR/rustdesk_data_*.tar.gz | awk '{print $9}' | nl

read -p "Enter backup number to restore: " BACKUP_NUM

# Get selected backup
BACKUP_FILE=$(ls $BACKUP_DIR/rustdesk_data_*.tar.gz | sed -n "${BACKUP_NUM}p")

if [ -z "$BACKUP_FILE" ]; then
    print_error "Invalid backup number"
    exit 1
fi

# Extract date from filename
BACKUP_DATE=$(basename $BACKUP_FILE | sed 's/rustdesk_data_//;s/.tar.gz//')

print_warning "This will restore backup from: $BACKUP_DATE"
print_warning "Current data will be backed up first"
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    print_info "Restore cancelled"
    exit 0
fi

# Stop services
print_info "Stopping services..."
docker-compose down

# Backup current state
print_info "Backing up current state..."
SAFETY_BACKUP="/tmp/rustdesk_safety_backup_$(date +%s)"
mkdir -p $SAFETY_BACKUP
[ -d "./data" ] && cp -r ./data $SAFETY_BACKUP/
[ -f ".env" ] && cp .env $SAFETY_BACKUP/
print_info "Current state backed up to: $SAFETY_BACKUP"

# Restore data
print_info "Restoring RustDesk data..."
rm -rf ./data
tar -xzf $BACKUP_DIR/rustdesk_data_$BACKUP_DATE.tar.gz -C .

# Restore configuration
if [ -f "$BACKUP_DIR/.env_$BACKUP_DATE" ]; then
    print_info "Restoring configuration..."
    cp $BACKUP_DIR/.env_$BACKUP_DATE .env
fi

if [ -f "$BACKUP_DIR/docker-compose_$BACKUP_DATE.yml" ]; then
    cp $BACKUP_DIR/docker-compose_$BACKUP_DATE.yml docker-compose.yml
fi

# Restore Nginx config
if [ -f "$BACKUP_DIR/nginx_config_$BACKUP_DATE.tar.gz" ]; then
    print_info "Restoring Nginx configuration..."
    tar -xzf $BACKUP_DIR/nginx_config_$BACKUP_DATE.tar.gz -C .
fi

# Restore certificates
if [ -f "$BACKUP_DIR/certs_$BACKUP_DATE.tar.gz" ]; then
    print_info "Restoring certificates..."
    tar -xzf $BACKUP_DIR/certs_$BACKUP_DATE.tar.gz -C .
fi

# Restore database
if [ -f "$BACKUP_DIR/rustdesk_db_$BACKUP_DATE.sql.gz" ]; then
    print_info "Starting database container..."
    docker-compose up -d postgres
    sleep 10
    
    print_info "Restoring database..."
    gunzip < $BACKUP_DIR/rustdesk_db_$BACKUP_DATE.sql.gz | \
        docker-compose exec -T postgres psql -U rustdesk_admin rustdesk
    
    print_info "Database restored"
fi

# Start all services
print_info "Starting all services..."
docker-compose up -d

sleep 10

# Verify
print_info "Verifying services..."
docker-compose ps

print_info "Restore completed successfully!"
echo ""
echo "Safety backup location: $SAFETY_BACKUP"
echo "You can delete it once you verify everything works correctly"
