#!/bin/bash
# RustDesk Update Script
# Update RustDesk containers to latest versions

set -e

PROJECT_DIR="/opt/rustdesk-remote-access-platform"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

cd $PROJECT_DIR

print_info "RustDesk Update Process"
echo "======================================"

# Backup first
print_warning "Creating safety backup before update..."
./scripts/backup.sh

# Pull latest images
print_info "Pulling latest Docker images..."
docker-compose pull

# Show differences
print_info "Checking for updates..."
docker-compose images

# Restart with new images
print_warning "This will restart all services. Continue? (y/n)"
read -p "> " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    print_info "Update cancelled"
    exit 0
fi

print_info "Stopping services..."
docker-compose down

print_info "Starting services with new images..."
docker-compose up -d

# Wait for startup
sleep 15

# Verify
print_info "Verifying services..."
docker-compose ps

# Clean up old images
print_info "Cleaning up old Docker images..."
docker image prune -a -f

print_info "Update completed successfully!"
echo ""
echo "Please verify all services are working correctly"
echo "Check logs: docker-compose logs -f"
