# RustDesk Remote Access Platform

Production-ready RustDesk server with Docker, Nginx reverse proxy, and optional Active Directory integration. Designed for secure remote access management supporting up to 8,000 devices with enterprise-grade security and scalability.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/boujrafh/rustdesk-remote-access-platform.git
cd rustdesk-remote-access-platform

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

## 📋 Features

- ✅ **Self-hosted RustDesk Server** - Full control over your remote access infrastructure
- ✅ **Nginx Reverse Proxy** - SSL/TLS termination and load balancing
- ✅ **Active Directory Integration** - Optional LDAP authentication
- ✅ **Docker-based Deployment** - Easy installation and updates
- ✅ **Production Security** - Hardened configuration with SSL, rate limiting, and security headers
- ✅ **Scalable Architecture** - Supports thousands of concurrent devices
- ✅ **Comprehensive Documentation** - Admin and user guides included

## 🏗️ Architecture

```
Internet
    │
    ├─> Nginx (443/TCP) ──> API Server (21114/TCP)
    │
    ├─> RustDesk hbbs (21115-21119/TCP+UDP)
    │
    └─> RustDesk hbbr (21117/TCP)
         │
         └─> PostgreSQL (Optional, for API)
```

### Port Requirements

| Port  | Protocol | Service | Purpose |
|-------|----------|---------|---------|
| 21115 | TCP | hbbs | ID/Rendezvous server |
| 21116 | TCP/UDP | hbbs | ID/Rendezvous server |
| 21117 | TCP | hbbr | Relay server |
| 21118 | TCP | hbbs | Web console (NAT) |
| 21119 | TCP | hbbr | Relay server (WebSocket) |
| 80 | TCP | Nginx | HTTP (redirect to HTTPS) |
| 443 | TCP | Nginx | HTTPS/Web console |
| 21114 | TCP | API | API server (optional) |

## 📦 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 2 CPU cores minimum (4+ recommended for 8000 devices)
- 4GB RAM minimum (8GB+ recommended)
- 50GB disk space
- Public IP address or domain name
- SSL certificate (Let's Encrypt recommended)

## 🔧 Installation

### 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Firewall Configuration

```bash
# UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp
sudo ufw enable

# Or firewalld
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=21115-21119/tcp
sudo firewall-cmd --permanent --add-port=21116/udp
sudo firewall-cmd --reload
```

### 3. SSL Certificate Setup

**Option A: Let's Encrypt (Recommended)**

```bash
# Install certbot
sudo apt install certbot -y

# Obtain certificate
sudo certbot certonly --standalone -d rustdesk.yourdomain.com

# Copy certificates
mkdir -p certs
sudo cp /etc/letsencrypt/live/rustdesk.yourdomain.com/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/rustdesk.yourdomain.com/privkey.pem certs/
sudo chmod 644 certs/*.pem
```

**Option B: Self-signed (Testing only)**

```bash
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/privkey.pem \
  -out certs/fullchain.pem \
  -subj "/CN=rustdesk.yourdomain.com"
```

### 4. Configuration

```bash
# Copy and edit environment file
cp .env.example .env
nano .env
```

**Required changes in `.env`:**
- `SERVER_DOMAIN`: Your domain name
- `PUBLIC_IP`: Your server's public IP
- `POSTGRES_PASSWORD`: Strong database password
- `API_SECRET_KEY`: Generate with `openssl rand -base64 32`
- `SESSION_SECRET`: Generate with `openssl rand -base64 32`

**For Active Directory integration:**
- Set `LDAP_ENABLED=true`
- Configure `LDAP_SERVER`, `LDAP_BASE_DN`, `LDAP_BIND_DN`, `LDAP_BIND_PASSWORD`

### 5. Deploy

```bash
# Basic deployment (ID and Relay servers only)
docker-compose up -d

# Full deployment (with API server and database)
docker-compose --profile full up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

## 🔐 Active Directory Integration

### AD Service Account Setup

1. Create a dedicated service account in AD:
   - Username: `svc_rustdesk`
   - Password: Strong, non-expiring
   - Permissions: Read access to user objects

2. Update `.env`:

```env
LDAP_ENABLED=true
LDAP_SERVER=ldap://dc01.yourdomain.com:389
LDAP_BASE_DN=DC=yourdomain,DC=com
LDAP_BIND_DN=CN=svc_rustdesk,OU=Service Accounts,DC=yourdomain,DC=com
LDAP_BIND_PASSWORD=YourServiceAccountPassword
```

3. Test LDAP connection:

```bash
docker-compose exec rustdesk-api ldapsearch -x -H ldap://your-ad-server:389 \
  -D "CN=svc_rustdesk,OU=Service Accounts,DC=yourdomain,DC=com" \
  -w YourPassword -b "DC=yourdomain,DC=com" "(objectClass=user)"
```

## 📊 Monitoring

### Health Checks

```bash
# Nginx health
curl https://rustdesk.yourdomain.com/health

# Container status
docker-compose ps

# Resource usage
docker stats

# Logs
docker-compose logs -f --tail=100
```

### Performance Tuning for 8000 Devices

Edit `docker-compose.yml` to add resource limits:

```yaml
services:
  hbbs:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

## 🔄 Maintenance

### Backup

```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/backup/rustdesk"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup data
tar -czf $BACKUP_DIR/rustdesk_data_$DATE.tar.gz ./data

# Backup database (if using full profile)
docker-compose exec -T postgres pg_dump -U rustdesk_admin rustdesk > $BACKUP_DIR/rustdesk_db_$DATE.sql

# Backup configuration
cp .env $BACKUP_DIR/.env_$DATE
cp docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml
```

### Updates

```bash
# Pull latest images
docker-compose pull

# Restart services
docker-compose down
docker-compose up -d

# Remove old images
docker image prune -a
```

### SSL Certificate Renewal

```bash
# Renew with certbot
sudo certbot renew

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/rustdesk.yourdomain.com/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/rustdesk.yourdomain.com/privkey.pem certs/

# Reload Nginx
docker-compose exec nginx nginx -s reload
```

## 🐛 Troubleshooting

### Connection Issues

```bash
# Check if ports are open
netstat -tulpn | grep -E '21115|21116|21117|443'

# Test from client
telnet your-server-ip 21116
```

### Performance Issues

```bash
# Check resource usage
docker stats

# Increase worker processes in nginx.conf
worker_processes 8;

# Adjust connection limits in .env
MAX_CONNECTIONS=15000
```

### LDAP Authentication Fails

```bash
# Test LDAP connectivity
docker-compose exec rustdesk-api ldapsearch -x -H $LDAP_SERVER \
  -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PASSWORD" \
  -b "$LDAP_BASE_DN" "(objectClass=user)"

# Check logs
docker-compose logs rustdesk-api | grep -i ldap
```

## 📚 Documentation

- [Admin Guide](docs/ADMIN_GUIDE.md) - Detailed administration manual
- [User Guide](docs/USER_GUIDE.md) - End-user connection instructions
- [Security Best Practices](docs/SECURITY.md) - Hardening and security guidelines
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture details

## 🤝 Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- Documentation: Check the `docs/` folder
- Issues: Open a GitHub issue
- Community: RustDesk official forums

## ⚠️ Security Notes

- Always use strong passwords
- Keep SSL certificates up to date
- Regularly update Docker images
- Enable firewall rules
- Monitor logs for suspicious activity
- Use LDAP over SSL (LDAPS) in production
- Implement network segmentation
- Regular security audits

## 🎯 Roadmap

- [ ] Kubernetes deployment manifests
- [ ] Prometheus monitoring integration
- [ ] Automated backup solution
- [ ] Multi-region deployment guide
- [ ] Advanced load balancing with HAProxy
- [ ] Integration with SSO providers (SAML, OAuth)

---

**Made with ❤️ for secure remote access**
