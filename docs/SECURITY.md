# Security Best Practices

## Overview

This document outlines security best practices for deploying and managing the RustDesk remote access platform.

## Network Security

### Firewall Configuration

**Minimum required ports:**
- TCP 21115-21119 (RustDesk services)
- UDP 21116 (RustDesk NAT traversal)
- TCP 80/443 (HTTP/HTTPS)

**Recommended firewall rules:**

```bash
# Allow only necessary traffic
sudo ufw default deny incoming
sudo ufw default allow outgoing

# RustDesk ports
sudo ufw allow from any to any port 21115:21119 proto tcp
sudo ufw allow from any to any port 21116 proto udp

# Web access
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# SSH (restrict to admin IPs)
sudo ufw allow from ADMIN_IP to any port 22

sudo ufw enable
```

### Network Segmentation

Isolate RustDesk infrastructure on separate VLAN/subnet.

### DDoS Protection

- Use Cloudflare or similar CDN for HTTPS endpoints
- Implement rate limiting (configured in Nginx)
- Monitor for abnormal traffic patterns

## Authentication Security

### Strong Password Policy

**Requirements:**
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- No dictionary words
- Change every 90 days

### Active Directory Integration

**Best practices:**
- Use dedicated service account with minimal privileges
- Implement account lockout policies
- Enable LDAPS (LDAP over SSL) on port 636
- Monitor authentication logs

### Two-Factor Authentication

Enable 2FA for administrator accounts when available.

## SSL/TLS Security

### Certificate Management

**Use Let's Encrypt for production:**

```bash
# Auto-renewal
0 3 * * * certbot renew --quiet --deploy-hook "docker-compose exec nginx nginx -s reload"
```

**TLS Configuration (nginx):**

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers off;
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
```

### HSTS

Enable HTTP Strict Transport Security:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

## Access Control

### Principle of Least Privilege

- Grant minimum necessary permissions
- Regular access reviews
- Remove unused accounts

### IP Whitelisting

For admin access:

```nginx
location /admin {
    allow 192.168.1.0/24;  # Admin network
    deny all;
    
    proxy_pass http://rustdesk-api:21114;
}
```

### Session Management

- Short session timeouts (15-30 minutes)
- Secure session cookies
- Log all authentication attempts

## Data Security

### Encryption at Rest

Encrypt backup storage:

```bash
# Encrypt backup
tar -czf - /path/to/data | openssl enc -aes-256-cbc -pbkdf2 -out backup.tar.gz.enc

# Decrypt backup
openssl enc -aes-256-cbc -pbkdf2 -d -in backup.tar.gz.enc | tar -xz
```

### Encryption in Transit

- All connections use TLS
- RustDesk uses end-to-end encryption
- No cleartext credentials in logs

### Database Security

**PostgreSQL hardening:**

```sql
-- Change default passwords
ALTER USER rustdesk_admin WITH PASSWORD 'NewStrongPassword';

-- Restrict connections
-- Edit pg_hba.conf:
host    rustdesk    rustdesk_admin    172.20.0.0/24    scram-sha-256

-- Regular backups
pg_dump rustdesk | gzip > backup_$(date +%F).sql.gz
```

## Container Security

### Docker Hardening

**Run as non-root:**

```yaml
services:
  hbbs:
    user: "1000:1000"  # Run as specific UID:GID
```

**Resource limits:**

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

**Read-only filesystem:**

```yaml
services:
  nginx:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

### Image Security

- Use official images only
- Regular security updates
- Scan for vulnerabilities

```bash
# Scan images
docker scan rustdesk/rustdesk-server:latest

# Update regularly
docker-compose pull
docker-compose up -d
```

## Logging and Monitoring

### Centralized Logging

Forward logs to SIEM:

```yaml
logging:
  driver: syslog
  options:
    syslog-address: "udp://siem.company.com:514"
    tag: "rustdesk"
```

### Security Events to Monitor

- Failed login attempts
- Unusual connection patterns
- Certificate expiry
- Service disruptions
- Configuration changes
- Privilege escalations

### Log Retention

- Keep logs for minimum 90 days
- Comply with regulatory requirements
- Secure log storage

## Incident Response

### Detection

Monitor for:
- Brute force attacks
- Unauthorized access
- Data exfiltration
- Service abuse

### Response Plan

1. **Identify** - Detect and verify incident
2. **Contain** - Isolate affected systems
3. **Eradicate** - Remove threat
4. **Recover** - Restore from backup
5. **Review** - Post-incident analysis

### Emergency Contacts

```
Security Team: security@company.com
24/7 Hotline: +1-XXX-XXX-XXXX
```

## Compliance

### Audit Requirements

- Regular security audits
- Penetration testing (annually)
- Compliance checks (GDPR, HIPAA, etc.)
- Access logs review

### Data Privacy

- Minimal data collection
- User consent for data processing
- Right to deletion
- Data portability

## Backup Security

### Backup Strategy

**3-2-1 Rule:**
- 3 copies of data
- 2 different media types
- 1 off-site backup

### Backup Encryption

Always encrypt backups:

```bash
# Encrypted backup
gpg --encrypt --recipient admin@company.com backup.tar.gz

# Verify backup integrity
sha256sum backup.tar.gz > backup.tar.gz.sha256
```

### Test Restorations

Monthly restoration tests in isolated environment.

## Updates and Patching

### Update Schedule

- **Critical**: Within 24 hours
- **High**: Within 7 days
- **Medium**: Within 30 days
- **Low**: Next maintenance window

### Update Process

```bash
# 1. Backup
./scripts/backup.sh

# 2. Test in staging
./scripts/update.sh

# 3. Deploy to production
# (after successful staging test)

# 4. Verify
./scripts/health-check.sh
```

## Security Checklist

### Initial Deployment

- [ ] Change all default passwords
- [ ] Configure firewall rules
- [ ] Enable SSL/TLS with valid certificate
- [ ] Configure AD/LDAP authentication
- [ ] Set up logging and monitoring
- [ ] Create backup schedule
- [ ] Document emergency procedures
- [ ] Perform security scan

### Monthly

- [ ] Review access logs
- [ ] Check for software updates
- [ ] Verify backup integrity
- [ ] Review firewall rules
- [ ] Certificate expiry check
- [ ] User access audit

### Quarterly

- [ ] Security assessment
- [ ] Penetration testing
- [ ] Disaster recovery drill
- [ ] Policy review
- [ ] Update documentation

## References

- NIST Cybersecurity Framework
- CIS Docker Benchmarks
- OWASP Security Guidelines
- RustDesk Security Documentation

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Classification**: Internal Use
