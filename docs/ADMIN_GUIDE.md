# RustDesk Platform - Administrator Guide

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation & Deployment](#installation--deployment)
3. [Configuration](#configuration)
4. [Active Directory Integration](#active-directory-integration)
5. [Security Hardening](#security-hardening)
6. [Monitoring & Logging](#monitoring--logging)
7. [Backup & Recovery](#backup--recovery)
8. [Performance Tuning](#performance-tuning)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance Tasks](#maintenance-tasks)

---

## System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disk**: 50GB SSD
- **Network**: 100Mbps dedicated
- **OS**: Ubuntu 20.04/22.04, Debian 11+, RHEL 8+, or Windows Server 2019+

### Recommended for 8000 Devices
- **CPU**: 8 cores (16 threads)
- **RAM**: 16GB-32GB
- **Disk**: 200GB NVMe SSD
- **Network**: 1Gbps dedicated with redundancy
- **OS**: Ubuntu 22.04 LTS Server

### Network Requirements
- Public static IP address
- Registered domain name with DNS control
- Firewall with the following ports open:
  - TCP: 80, 443, 21115, 21116, 21117, 21118, 21119
  - UDP: 21116

---

## Installation & Deployment

### Step 1: Server Preparation

#### Linux (Ubuntu/Debian)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl git vim ufw certbot

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

#### Windows Server

```powershell
# Install Docker Desktop for Windows Server
# Download from: https://docs.docker.com/desktop/install/windows-install/

# Or use Docker Engine with WSL2
wsl --install
wsl --set-default-version 2

# Install Docker in WSL2 Ubuntu
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Step 2: Clone Repository

```bash
cd /opt
git clone https://github.com/boujrafh/rustdesk-remote-access-platform.git
cd rustdesk-remote-access-platform
```

### Step 3: SSL Certificate Setup

#### Production (Let's Encrypt)

```bash
# Stop any service using port 80
sudo systemctl stop nginx 2>/dev/null || true

# Obtain certificate
sudo certbot certonly --standalone \
  -d rustdesk.yourdomain.com \
  --agree-tos \
  --email admin@yourdomain.com \
  --non-interactive

# Copy certificates
mkdir -p certs
sudo cp /etc/letsencrypt/live/rustdesk.yourdomain.com/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/rustdesk.yourdomain.com/privkey.pem certs/
sudo chmod 644 certs/*.pem
sudo chown $USER:$USER certs/*.pem

# Setup auto-renewal
sudo crontab -e
# Add: 0 3 * * * certbot renew --quiet --deploy-hook "cd /opt/rustdesk-remote-access-platform && cp /etc/letsencrypt/live/rustdesk.yourdomain.com/*.pem certs/ && docker-compose exec nginx nginx -s reload"
```

#### Development (Self-signed)

```bash
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/privkey.pem \
  -out certs/fullchain.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=rustdesk.local"
```

### Step 4: Configuration

```bash
# Copy environment template
cp .env.example .env

# Generate secrets
API_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 24)

# Edit configuration
nano .env
```

**Critical `.env` settings:**

```env
# Server Configuration
SERVER_DOMAIN=rustdesk.yourdomain.com
PUBLIC_IP=203.0.113.45
RELAY_SERVER=rustdesk-hbbr

# Database (strong password)
POSTGRES_PASSWORD=$DB_PASSWORD

# Security keys (generated above)
API_SECRET_KEY=$API_SECRET
SESSION_SECRET=$SESSION_SECRET
```

### Step 5: Deploy Services

```bash
# Basic deployment (ID + Relay servers)
docker-compose up -d

# Full deployment (with API server and DB)
docker-compose --profile full up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

### Step 6: Firewall Configuration

#### UFW (Ubuntu/Debian)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp
sudo ufw enable
sudo ufw status verbose
```

#### Firewalld (RHEL/CentOS)

```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=21115-21119/tcp
sudo firewall-cmd --permanent --add-port=21116/udp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

#### Windows Firewall

```powershell
# Allow HTTP/HTTPS
New-NetFirewallRule -DisplayName "RustDesk HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "RustDesk HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Allow RustDesk ports
New-NetFirewallRule -DisplayName "RustDesk TCP" -Direction Inbound -Protocol TCP -LocalPort 21115,21116,21117,21118,21119 -Action Allow
New-NetFirewallRule -DisplayName "RustDesk UDP" -Direction Inbound -Protocol UDP -LocalPort 21116 -Action Allow
```

---

## Configuration

### Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_DOMAIN` | - | Your public domain name |
| `PUBLIC_IP` | - | Server's public IP address |
| `RELAY_SERVER` | rustdesk-hbbr | Internal relay server hostname |
| `DOCKER_SUBNET` | 172.20.0.0/24 | Docker network subnet |
| `POSTGRES_PASSWORD` | - | Database password (required for full profile) |
| `LDAP_ENABLED` | false | Enable Active Directory integration |
| `LDAP_SERVER` | - | AD server URL (ldap://server:389) |
| `LDAP_BASE_DN` | - | LDAP base DN |
| `LOG_LEVEL` | info | Logging level (debug, info, warn, error) |
| `MAX_CONNECTIONS` | 10000 | Maximum concurrent connections |

### Nginx Configuration

Located in `nginx/conf.d/rustdesk.conf`:

**Key settings:**
- SSL certificate paths
- Rate limiting: 10 requests/second per IP
- Connection limit: 10 concurrent per IP
- Proxy timeouts: 60 seconds
- HSTS enabled (31536000 seconds)

To modify:
```bash
nano nginx/conf.d/rustdesk.conf
docker-compose exec nginx nginx -t  # Test configuration
docker-compose restart nginx
```

### Docker Resource Limits

Edit `docker-compose.yml` to add resource constraints:

```yaml
services:
  hbbs:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

---

## Active Directory Integration

### Prerequisites

1. AD domain controller accessible from RustDesk server
2. Service account with read permissions
3. Network connectivity on port 389 (LDAP) or 636 (LDAPS)

### Step 1: Create AD Service Account

```powershell
# On your AD Domain Controller
New-ADUser -Name "RustDesk Service" `
  -SamAccountName "svc_rustdesk" `
  -UserPrincipalName "svc_rustdesk@yourdomain.com" `
  -Path "OU=Service Accounts,DC=yourdomain,DC=com" `
  -AccountPassword (ConvertTo-SecureString "YourStrongPassword123!" -AsPlainText -Force) `
  -Enabled $true `
  -PasswordNeverExpires $true `
  -CannotChangePassword $true

# Grant read permissions
Add-ADGroupMember -Identity "Domain Users" -Members "svc_rustdesk"
```

### Step 2: Configure LDAP Settings

Update `.env`:

```env
LDAP_ENABLED=true
LDAP_SERVER=ldap://dc01.yourdomain.com:389
LDAP_BASE_DN=DC=yourdomain,DC=com
LDAP_BIND_DN=CN=svc_rustdesk,OU=Service Accounts,DC=yourdomain,DC=com
LDAP_BIND_PASSWORD=YourStrongPassword123!
LDAP_USER_FILTER=(objectClass=user)
LDAP_GROUP_FILTER=(objectClass=group)
```

For LDAPS (recommended):
```env
LDAP_SERVER=ldaps://dc01.yourdomain.com:636
```

### Step 3: Test LDAP Connection

```bash
# Install LDAP utilities
sudo apt install ldap-utils -y

# Test connection
ldapsearch -x \
  -H ldap://dc01.yourdomain.com:389 \
  -D "CN=svc_rustdesk,OU=Service Accounts,DC=yourdomain,DC=com" \
  -w "YourStrongPassword123!" \
  -b "DC=yourdomain,DC=com" \
  "(objectClass=user)" sAMAccountName

# Test from container
docker-compose exec rustdesk-api \
  ldapsearch -x -H $LDAP_SERVER \
  -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASSWORD" \
  -b "$LDAP_BASE_DN" "(objectClass=user)"
```

### Step 4: Restart Services

```bash
docker-compose restart rustdesk-api
docker-compose logs -f rustdesk-api
```

### Troubleshooting LDAP

**Connection timeout:**
```bash
# Check network connectivity
telnet dc01.yourdomain.com 389

# Check DNS resolution
nslookup dc01.yourdomain.com

# Check firewall
sudo ufw status
```

**Authentication failed:**
```bash
# Verify credentials
ldapwhoami -x -H ldap://dc01.yourdomain.com:389 \
  -D "CN=svc_rustdesk,OU=Service Accounts,DC=yourdomain,DC=com" \
  -w "YourPassword"

# Check account status in AD
```

---

## Security Hardening

### 1. SSL/TLS Configuration

**Enforce strong ciphers** in `nginx/conf.d/rustdesk.conf`:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers off;
```

### 2. Rate Limiting

Already configured in Nginx:
- 10 requests/second per IP
- Burst of 20 requests
- Max 10 concurrent connections per IP

Adjust in `nginx/conf.d/rustdesk.conf`:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=20r/s;
limit_req zone=api_limit burst=50 nodelay;
```

### 3. Fail2ban Integration

```bash
# Install Fail2ban
sudo apt install fail2ban -y

# Create filter
sudo nano /etc/fail2ban/filter.d/rustdesk.conf
```

```ini
[Definition]
failregex = ^<HOST> .* "(GET|POST).*" (404|403|401) .*$
ignoreregex =
```

```bash
# Configure jail
sudo nano /etc/fail2ban/jail.local
```

```ini
[rustdesk]
enabled = true
port = 80,443,21115,21116,21117,21118,21119
filter = rustdesk
logpath = /opt/rustdesk-remote-access-platform/nginx/logs/access.log
maxretry = 5
bantime = 3600
findtime = 600
```

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status rustdesk
```

### 4. Docker Security

```bash
# Run Docker in rootless mode
dockerd-rootless-setuptool.sh install

# Enable user namespaces
sudo nano /etc/docker/daemon.json
```

```json
{
  "userns-remap": "default",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
```

### 5. Network Segmentation

Create isolated Docker network:

```yaml
# In docker-compose.yml
networks:
  rustdesk-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
          gateway: 172.20.0.1
    driver_opts:
      com.docker.network.bridge.name: br-rustdesk
```

---

## Monitoring & Logging

### Container Health Checks

```bash
# Check container status
docker-compose ps

# View real-time stats
docker stats

# Detailed container inspection
docker inspect rustdesk-hbbs
```

### Centralized Logging

#### Option 1: Local Log Aggregation

```bash
# View all logs
docker-compose logs -f

# Specific service
docker-compose logs -f hbbs

# Last 100 lines
docker-compose logs --tail=100 hbbs

# Since timestamp
docker-compose logs --since 2024-01-01T00:00:00 hbbs
```

#### Option 2: Syslog Integration

Add to `docker-compose.yml`:

```yaml
services:
  hbbs:
    logging:
      driver: syslog
      options:
        syslog-address: "udp://192.168.1.10:514"
        tag: "rustdesk-hbbs"
```

### Prometheus Monitoring

Create `prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'rustdesk'
    static_configs:
      - targets: ['rustdesk-api:21114']
```

Add to `docker-compose.yml`:

```yaml
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - rustdesk-network
```

### Email Alerts

Configure SMTP in `.env` and set up alerting script:

```bash
#!/bin/bash
# /opt/rustdesk-remote-access-platform/scripts/alert.sh

SERVICE=$1
STATUS=$2

if [ "$STATUS" != "healthy" ]; then
    echo "Alert: $SERVICE is $STATUS" | \
    mail -s "RustDesk Alert: $SERVICE Down" admin@yourdomain.com
fi
```

---

## Backup & Recovery

### Automated Backup Script

Create `/opt/rustdesk-remote-access-platform/scripts/backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/backup/rustdesk"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup RustDesk data
tar -czf $BACKUP_DIR/rustdesk_data_$DATE.tar.gz \
  -C /opt/rustdesk-remote-access-platform ./data

# Backup database (if using full profile)
if docker-compose ps | grep -q rustdesk-db; then
    docker-compose exec -T postgres pg_dump -U rustdesk_admin rustdesk | \
    gzip > $BACKUP_DIR/rustdesk_db_$DATE.sql.gz
fi

# Backup configuration
cp /opt/rustdesk-remote-access-platform/.env $BACKUP_DIR/.env_$DATE
cp /opt/rustdesk-remote-access-platform/docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml

# Backup certificates
tar -czf $BACKUP_DIR/certs_$DATE.tar.gz \
  -C /opt/rustdesk-remote-access-platform ./certs

# Remove old backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Log
echo "$(date): Backup completed successfully" >> /var/log/rustdesk-backup.log
```

```bash
chmod +x scripts/backup.sh

# Schedule with cron
crontab -e
# Add: 0 2 * * * /opt/rustdesk-remote-access-platform/scripts/backup.sh
```

### Recovery Procedure

```bash
# Stop services
cd /opt/rustdesk-remote-access-platform
docker-compose down

# Restore data
tar -xzf /backup/rustdesk/rustdesk_data_20240101_020000.tar.gz -C ./

# Restore database
gunzip < /backup/rustdesk/rustdesk_db_20240101_020000.sql.gz | \
  docker-compose exec -T postgres psql -U rustdesk_admin rustdesk

# Restore configuration
cp /backup/rustdesk/.env_20240101_020000 .env
cp /backup/rustdesk/docker-compose_20240101_020000.yml docker-compose.yml

# Restore certificates
tar -xzf /backup/rustdesk/certs_20240101_020000.tar.gz -C ./

# Start services
docker-compose up -d
```

---

## Performance Tuning

### For 8000 Concurrent Devices

#### 1. System Kernel Parameters

```bash
sudo nano /etc/sysctl.conf
```

```ini
# Network performance
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# File descriptors
fs.file-max = 2097152
fs.nr_open = 2097152

# Memory
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
```

```bash
sudo sysctl -p
```

#### 2. Docker Resource Allocation

Update `docker-compose.yml`:

```yaml
services:
  hbbs:
    deploy:
      resources:
        limits:
          cpus: '6'
          memory: 12G
        reservations:
          cpus: '4'
          memory: 8G
    ulimits:
      nofile:
        soft: 65536
        hard: 65536

  hbbr:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

#### 3. Nginx Optimization

```nginx
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 10000;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    
    # Connection pooling
    upstream rustdesk_api {
        least_conn;
        server rustdesk-api:21114 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
}
```

#### 4. Database Tuning (PostgreSQL)

```bash
# Create custom PostgreSQL config
mkdir -p postgres/config
nano postgres/config/postgresql.conf
```

```ini
# Memory
shared_buffers = 4GB
effective_cache_size = 12GB
work_mem = 64MB
maintenance_work_mem = 1GB

# Checkpoints
checkpoint_completion_target = 0.9
wal_buffers = 16MB
max_wal_size = 4GB

# Connections
max_connections = 500

# Performance
random_page_cost = 1.1  # For SSD
effective_io_concurrency = 200
```

Update `docker-compose.yml`:

```yaml
  postgres:
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    volumes:
      - ./postgres/config/postgresql.conf:/etc/postgresql/postgresql.conf:ro
```

---

## Troubleshooting

### Common Issues

#### 1. Connection Refused on Port 21116

**Symptoms**: Clients cannot connect to server

**Solutions**:
```bash
# Check if service is running
docker-compose ps

# Check port binding
netstat -tulpn | grep 21116

# Check firewall
sudo ufw status | grep 21116

# Test port
telnet YOUR_SERVER_IP 21116
```

#### 2. SSL Certificate Errors

**Symptoms**: Browser shows SSL warning

**Solutions**:
```bash
# Check certificate validity
openssl x509 -in certs/fullchain.pem -text -noout

# Verify certificate chain
openssl verify -CAfile certs/fullchain.pem certs/fullchain.pem

# Renew Let's Encrypt certificate
sudo certbot renew --force-renewal
```

#### 3. High CPU Usage

**Symptoms**: Server becomes slow, CPU at 100%

**Solutions**:
```bash
# Check which container is consuming CPU
docker stats

# Check for connection floods
netstat -an | grep :21116 | wc -l

# Implement rate limiting
# Edit nginx/conf.d/rustdesk.conf and reduce rate limit

# Scale horizontally (add more relay servers)
```

#### 4. Database Connection Errors

**Symptoms**: API server cannot connect to database

**Solutions**:
```bash
# Check database status
docker-compose exec postgres pg_isready

# Check connection string
docker-compose exec rustdesk-api env | grep DB_URL

# Reset database password
docker-compose exec postgres psql -U postgres -c "ALTER USER rustdesk_admin WITH PASSWORD 'NewPassword';"
```

#### 5. LDAP Authentication Fails

**Symptoms**: Users cannot log in with AD credentials

**Solutions**:
```bash
# Test LDAP connectivity
ldapsearch -x -H $LDAP_SERVER -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASSWORD" -b "$LDAP_BASE_DN"

# Check service account
# Verify account is not locked/expired in AD

# Enable debug logging
# Set LOG_LEVEL=debug in .env
docker-compose restart rustdesk-api
docker-compose logs -f rustdesk-api | grep -i ldap
```

---

## Maintenance Tasks

### Daily Tasks

```bash
# Check service health
docker-compose ps

# Review logs for errors
docker-compose logs --tail=50 | grep -i error

# Monitor resource usage
docker stats --no-stream
```

### Weekly Tasks

```bash
# Check disk space
df -h

# Review security logs
sudo grep -i "failed\|error" /var/log/auth.log

# Check for updates
docker-compose pull
```

### Monthly Tasks

```bash
# Rotate logs
docker-compose down
find . -name "*.log" -mtime +30 -delete
docker-compose up -d

# Review and update firewall rules
sudo ufw status numbered

# Test backup restoration (in test environment)

# Update SSL certificates
sudo certbot renew

# Review user access (LDAP)

# Performance audit
```

### Quarterly Tasks

```bash
# Security audit
# - Review user permissions
# - Check for unused accounts
# - Update passwords

# Capacity planning
# - Analyze growth trends
# - Plan for scaling

# Disaster recovery test

# Update documentation
```

---

## Emergency Contacts & Escalation

### Incident Response Checklist

1. ☐ Identify the issue
2. ☐ Check service status
3. ☐ Review recent changes
4. ☐ Check logs
5. ☐ Attempt standard troubleshooting
6. ☐ Escalate if unresolved
7. ☐ Document incident
8. ☐ Implement preventive measures

### Support Resources

- **Official RustDesk Documentation**: https://rustdesk.com/docs/
- **GitHub Issues**: https://github.com/rustdesk/rustdesk-server
- **Community Forum**: https://github.com/rustdesk/rustdesk/discussions

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Maintained By**: Platform Team
