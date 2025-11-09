#!/bin/bash
# RustDesk Health Check Script
# Monitor system health and alert on issues

PROJECT_DIR="/opt/rustdesk-remote-access-platform"
LOG_FILE="/var/log/rustdesk-health.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo -e "$1"
}

check_service() {
    SERVICE=$1
    if docker-compose ps | grep -q "$SERVICE.*Up"; then
        log_msg "${GREEN}✓${NC} $SERVICE is running"
        return 0
    else
        log_msg "${RED}✗${NC} $SERVICE is NOT running"
        return 1
    fi
}

cd $PROJECT_DIR

log_msg "====== RustDesk Health Check ======"

# Check Docker daemon
if ! systemctl is-active --quiet docker; then
    log_msg "${RED}✗ Docker daemon is not running${NC}"
    exit 1
fi
log_msg "${GREEN}✓${NC} Docker daemon is running"

# Check containers
FAILED=0
check_service "rustdesk-hbbs" || FAILED=1
check_service "rustdesk-hbbr" || FAILED=1
check_service "rustdesk-nginx" || FAILED=1

# Check disk space
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_msg "${RED}✗ Disk usage critical: ${DISK_USAGE}%${NC}"
    FAILED=1
elif [ "$DISK_USAGE" -gt 80 ]; then
    log_msg "${YELLOW}⚠ Disk usage warning: ${DISK_USAGE}%${NC}"
else
    log_msg "${GREEN}✓${NC} Disk usage OK: ${DISK_USAGE}%"
fi

# Check memory
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEM_USAGE" -gt 90 ]; then
    log_msg "${RED}✗ Memory usage critical: ${MEM_USAGE}%${NC}"
    FAILED=1
elif [ "$MEM_USAGE" -gt 80 ]; then
    log_msg "${YELLOW}⚠ Memory usage warning: ${MEM_USAGE}%${NC}"
else
    log_msg "${GREEN}✓${NC} Memory usage OK: ${MEM_USAGE}%"
fi

# Check SSL certificate expiry
if [ -f "certs/fullchain.pem" ]; then
    CERT_EXPIRY=$(openssl x509 -in certs/fullchain.pem -noout -enddate | cut -d= -f2)
    EXPIRY_DATE=$(date -d "$CERT_EXPIRY" +%s)
    NOW=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_DATE - $NOW) / 86400 ))
    
    if [ "$DAYS_LEFT" -lt 7 ]; then
        log_msg "${RED}✗ SSL certificate expires in $DAYS_LEFT days!${NC}"
        FAILED=1
    elif [ "$DAYS_LEFT" -lt 30 ]; then
        log_msg "${YELLOW}⚠ SSL certificate expires in $DAYS_LEFT days${NC}"
    else
        log_msg "${GREEN}✓${NC} SSL certificate valid ($DAYS_LEFT days remaining)"
    fi
fi

# Check network connectivity
if curl -s -o /dev/null -w "%{http_code}" https://localhost/health | grep -q "200"; then
    log_msg "${GREEN}✓${NC} Web server responding"
else
    log_msg "${RED}✗ Web server not responding${NC}"
    FAILED=1
fi

# Summary
if [ $FAILED -eq 0 ]; then
    log_msg "${GREEN}====== All checks passed ======${NC}"
    exit 0
else
    log_msg "${RED}====== Health check FAILED ======${NC}"
    
    # Send alert email (if configured)
    if [ -n "$ALERT_EMAIL" ]; then
        echo "RustDesk health check failed. See $LOG_FILE for details." | \
            mail -s "RustDesk Alert: Health Check Failed" $ALERT_EMAIL
    fi
    
    exit 1
fi
