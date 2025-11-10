# Guide de Déploiement Multi-Environnements RustDesk

Déploiement de RustDesk sur 3 environnements isolés avec architecture relay séparée pour 8000 machines.

## 🏗️ Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────┐
│                          INTERNET / VPN                              │
└─────────────────────────────────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────┐
│ ENVIRONNEMENT 1: Office + Industrial (~4000 machines)                │
│ ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐            │
│ │ hbbs (ID/RDV)   │→ │ hbbr Relay 1 │  │ hbbr Relay 2 │            │
│ │ 10.10.0.100     │  │ 10.10.0.101  │  │ 10.10.0.102  │            │
│ └─────────────────┘  └──────────────┘  └──────────────┘            │
│ Serveur: rustdesk-office.bh-systems.be                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ ENVIRONNEMENT 2: MCN Sécurisé (~2000 machines)                       │
│ ┌─────────────────┐  ┌──────────────┐                               │
│ │ hbbs (ID/RDV)   │→ │ hbbr Relay   │  Firewall strict              │
│ │ 172.20.0.100    │  │ 172.20.0.101 │  Ports: 21115-21119           │
│ └─────────────────┘  └──────────────┘                               │
│ Serveur: rustdesk-mcn.bh-systems.be                                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ ENVIRONNEMENT 3: SFN Sécurisé (~2000 machines)                       │
│ ┌─────────────────┐  ┌──────────────┐                               │
│ │ hbbs (ID/RDV)   │→ │ hbbr Relay   │  Firewall strict              │
│ │ 172.30.0.100    │  │ 172.30.0.101 │  Ports: 21115-21119           │
│ └─────────────────┘  └──────────────┘                               │
│ Serveur: rustdesk-sfn.bh-systems.be                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## 📋 Table des Matières

1. [Pourquoi séparer les Relay Servers](#pourquoi-séparer-les-relay-servers)
2. [Prérequis](#prérequis)
3. [Déploiement Environnement Office](#déploiement-environnement-office)
4. [Déploiement Environnement MCN](#déploiement-environnement-mcn)
5. [Déploiement Environnement SFN](#déploiement-environnement-sfn)
6. [Configuration Firewall](#configuration-firewall)
7. [Haute Disponibilité](#haute-disponibilité)
8. [Monitoring et Maintenance](#monitoring-et-maintenance)

## 🔧 Pourquoi séparer les Relay Servers ?

### **Architecture Séparée (RECOMMANDÉ pour 8000 machines)**

```
┌──────────────────┐
│  ID/RDV Server   │  ← Léger: gère uniquement les connexions (~100 MB RAM)
│   (hbbs)         │     • Enregistrement des clients
│  IP: 10.10.0.100 │     • Gestion des IDs
└──────────────────┘     • Coordination NAT
         ↓
┌──────────────────┐
│  Relay Server 1  │  ← Lourd: transfert des données (~4 GB RAM)
│   (hbbr)         │     • Flux vidéo
│  IP: 10.10.0.101 │     • Transfert de fichiers
└──────────────────┘     • Audio

┌──────────────────┐
│  Relay Server 2  │  ← Backup / Load balancing
│   (hbbr)         │
│  IP: 10.10.0.102 │
└──────────────────┘
```

### **Avantages**

| Aspect | Serveur Unique | Serveurs Séparés |
|--------|----------------|------------------|
| **Performance** | ⚠️ Goulet d'étranglement | ✅ Charge distribuée |
| **Scalabilité** | ❌ Limitée | ✅ Horizontale (ajout de relays) |
| **Disponibilité** | ❌ SPOF (Single Point of Failure) | ✅ Redondance possible |
| **Bande passante** | ⚠️ Saturée rapidement | ✅ Répartie |
| **Maintenance** | ⚠️ Downtime total | ✅ Mise à jour progressive |

### **Seuils recommandés**

- **< 100 machines** : Serveur unique acceptable
- **100-500 machines** : Séparation recommandée
- **> 500 machines** : Séparation **OBLIGATOIRE**
- **> 2000 machines** : Multiple relays + load balancing

## 📦 Prérequis

### Matériel recommandé par environnement

#### Office (4000 machines)
- **hbbs** : 4 vCPU, 8 GB RAM, 100 GB SSD
- **hbbr-1** : 8 vCPU, 16 GB RAM, 200 GB SSD, 1 Gbps
- **hbbr-2** : 8 vCPU, 16 GB RAM, 200 GB SSD, 1 Gbps (HA)

#### MCN/SFN (2000 machines chacun)
- **hbbs** : 2 vCPU, 4 GB RAM, 50 GB SSD
- **hbbr** : 4 vCPU, 8 GB RAM, 100 GB SSD, 500 Mbps

### Logiciels requis

```bash
# Docker & Docker Compose
docker --version  # >= 24.0
docker compose version  # >= 2.20

# Certificats SSL
openssl version  # Pour génération de certificats

# Outils réseau
nc, telnet, ping  # Tests de connectivité
```

## 🚀 Déploiement Environnement Office

### Étape 1: Préparation

```bash
# Cloner le repository
git clone https://github.com/boujrafh/rustdesk-remote-access-platform.git
cd rustdesk-remote-access-platform

# Créer les dossiers nécessaires
mkdir -p certs/office data postgres-data api-data logs
```

### Étape 2: Configuration

```bash
# Copier et éditer la configuration Office
cp .env.prod-office .env

# Éditer les valeurs
nano .env
```

**Valeurs à modifier** :

```env
# IPs réelles de vos serveurs
HBBS_IP=10.10.0.100
HBBR_PRIMARY_IP=10.10.0.101
HBBR_SECONDARY_IP=10.10.0.102

# Générer les secrets
POSTGRES_PASSWORD=$(openssl rand -base64 32)
API_SECRET_KEY=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)

# LDAP Active Directory
LDAP_SERVER=ldap://ad-office.bh-systems.be:389
LDAP_BIND_PASSWORD=votre_mot_de_passe_ldap
```

### Étape 3: Certificats SSL

```bash
# Option A: Let's Encrypt (recommandé)
certbot certonly --standalone -d rustdesk-office.bh-systems.be
cp /etc/letsencrypt/live/rustdesk-office.bh-systems.be/fullchain.pem certs/office/
cp /etc/letsencrypt/live/rustdesk-office.bh-systems.be/privkey.pem certs/office/

# Option B: Certificat auto-signé (dev/test uniquement)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/office/privkey.pem \
  -out certs/office/fullchain.pem \
  -subj "/CN=rustdesk-office.bh-systems.be"
```

### Étape 4: Déploiement

```bash
# Déploiement minimal (sans API/DB)
docker compose -f docker-compose.prod.yml up -d

# Déploiement complet (avec API, DB, Redis)
docker compose -f docker-compose.prod.yml --profile full up -d

# Déploiement haute disponibilité (avec relay secondaire)
docker compose -f docker-compose.prod.yml --profile full --profile ha up -d
```

### Étape 5: Vérification

```bash
# Vérifier les conteneurs
docker compose -f docker-compose.prod.yml ps

# Vérifier les logs
docker logs rustdesk-hbbs
docker logs rustdesk-hbbr

# Tester la connectivité
telnet 10.10.0.100 21116  # hbbs
telnet 10.10.0.101 21117  # hbbr

# Récupérer la clé publique
docker exec rustdesk-hbbs cat /root/id_ed25519.pub
```

## 🔒 Déploiement Environnement MCN

### Configuration spécifique MCN

```bash
# Utiliser la configuration MCN
cp .env.prod-mcn .env

# Éditer avec les valeurs MCN
nano .env
```

**Différences clés** :

```env
SERVER_DOMAIN=rustdesk-mcn.bh-systems.be
HBBS_IP=172.20.0.100
HBBR_PRIMARY_IP=172.20.0.101
DOCKER_SUBNET=172.22.0.0/24

# LDAP MCN séparé
LDAP_SERVER=ldap://ad-mcn.bh-systems.be:389
LDAP_BASE_DN=DC=mcn,DC=bh-systems,DC=be
LDAP_ALLOWED_GROUPS=CN=MCN-Admins,OU=Groups,DC=mcn,DC=bh-systems,DC=be
```

### Firewall MCN (STRICT)

```bash
# Linux (iptables)
./scripts/firewall-mcn.sh enable

# Windows (PowerShell)
.\scripts\firewall-mcn.ps1 -Action Enable
```

Voir section [Configuration Firewall](#configuration-firewall) pour détails.

## 🔐 Déploiement Environnement SFN

Identique à MCN avec les paramètres SFN :

```bash
cp .env.prod-sfn .env
# Éditer selon vos besoins
docker compose -f docker-compose.prod.yml --profile full up -d
./scripts/firewall-sfn.sh enable
```

## 🔥 Configuration Firewall

### Ports requis

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 21115 | TCP | hbbs | NAT type test |
| 21116 | TCP/UDP | hbbs | ID registration & heartbeat |
| 21117 | TCP | hbbr | Relay |
| 21118 | TCP | hbbs | WebSocket |
| 21119 | TCP | hbbr | WebSocket relay |
| 443 | TCP | nginx | HTTPS (API) |

### Linux (iptables) - MCN/SFN

```bash
#!/bin/bash
# firewall-mcn.sh

# Flush existing rules
iptables -F
iptables -X

# Default policy: DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# RustDesk ports UNIQUEMENT
iptables -A INPUT -p tcp --dport 21115 -j ACCEPT
iptables -A INPUT -p tcp --dport 21116 -j ACCEPT
iptables -A INPUT -p udp --dport 21116 -j ACCEPT
iptables -A INPUT -p tcp --dport 21117 -j ACCEPT
iptables -A INPUT -p tcp --dport 21118 -j ACCEPT
iptables -A INPUT -p tcp --dport 21119 -j ACCEPT

# HTTPS pour API (optionnel)
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# SSH (administration uniquement depuis réseau admin)
iptables -A INPUT -p tcp -s 10.0.0.0/8 --dport 22 -j ACCEPT

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "DROPPED: "

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### Windows Firewall - MCN/SFN

```powershell
# firewall-mcn.ps1

param(
    [ValidateSet('Enable','Disable')]
    [string]$Action = 'Enable'
)

if ($Action -eq 'Enable') {
    # Bloquer tout par défaut
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
    
    # Autoriser RustDesk uniquement
    New-NetFirewallRule -DisplayName "RustDesk hbbs TCP 21115" -Direction Inbound -Protocol TCP -LocalPort 21115 -Action Allow
    New-NetFirewallRule -DisplayName "RustDesk hbbs TCP 21116" -Direction Inbound -Protocol TCP -LocalPort 21116 -Action Allow
    New-NetFirewallRule -DisplayName "RustDesk hbbs UDP 21116" -Direction Inbound -Protocol UDP -LocalPort 21116 -Action Allow
    New-NetFirewallRule -DisplayName "RustDesk hbbr TCP 21117" -Direction Inbound -Protocol TCP -LocalPort 21117 -Action Allow
    New-NetFirewallRule -DisplayName "RustDesk hbbs WS 21118" -Direction Inbound -Protocol TCP -LocalPort 21118 -Action Allow
    New-NetFirewallRule -DisplayName "RustDesk hbbr WS 21119" -Direction Inbound -Protocol TCP -LocalPort 21119 -Action Allow
    
    Write-Host "Firewall MCN activé" -ForegroundColor Green
} else {
    # Désactiver
    Remove-NetFirewallRule -DisplayName "RustDesk*" -ErrorAction SilentlyContinue
    Write-Host "Firewall MCN désactivé" -ForegroundColor Yellow
}
```

## 🔄 Haute Disponibilité

### Load Balancing des Relays

Avec 2+ relay servers, RustDesk choisit automatiquement le meilleur relay disponible.

**Configuration** :

```yaml
# docker-compose.prod.yml
# Démarrer avec le profile 'ha'
docker compose -f docker-compose.prod.yml --profile ha --profile full up -d
```

### Monitoring de santé

```bash
# Script de monitoring
#!/bin/bash
# health-check-ha.sh

check_service() {
    local host=$1
    local port=$2
    nc -z -w5 $host $port
    return $?
}

# Check hbbs
if check_service 10.10.0.100 21116; then
    echo "✅ hbbs OK"
else
    echo "❌ hbbs DOWN - ALERTE!"
    # Envoyer notification
fi

# Check relay primary
if check_service 10.10.0.101 21117; then
    echo "✅ Relay 1 OK"
else
    echo "⚠️  Relay 1 DOWN - Basculement sur Relay 2"
fi

# Check relay secondary
if check_service 10.10.0.102 21117; then
    echo "✅ Relay 2 OK"
else
    echo "❌ Relay 2 DOWN"
fi
```

### Failover automatique

Les clients RustDesk basculent automatiquement sur le relay secondaire si le primaire est indisponible.

## 📊 Monitoring et Maintenance

### Vérifier les clients connectés

```bash
# Compter les clients
docker exec rustdesk-hbbs sqlite3 /root/db_v2.sqlite3 \
  "SELECT COUNT(*) as total_clients FROM peer;"

# Lister les 20 derniers clients
docker exec rustdesk-hbbs sqlite3 /root/db_v2.sqlite3 \
  "SELECT id, last_reg_time FROM peer ORDER BY last_reg_time DESC LIMIT 20;"

# Statistiques par environnement
docker exec rustdesk-hbbs sqlite3 /root/db_v2.sqlite3 \
  "SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN last_reg_time > datetime('now', '-1 hour') THEN 1 END) as active_1h,
    COUNT(CASE WHEN last_reg_time > datetime('now', '-24 hours') THEN 1 END) as active_24h
  FROM peer;"
```

### Logs centralisés

```bash
# Tous les logs
docker compose -f docker-compose.prod.yml logs -f

# Logs spécifiques
docker logs -f rustdesk-hbbs
docker logs -f rustdesk-hbbr
docker logs -f rustdesk-api

# Erreurs uniquement
docker logs rustdesk-hbbs 2>&1 | grep ERROR
```

### Backups automatiques

```bash
# Script de backup
#!/bin/bash
# backup-rustdesk.sh

BACKUP_DIR="/backups/rustdesk-office"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup base de données
docker exec rustdesk-db pg_dump -U rustdesk_admin rustdesk_office > \
  "$BACKUP_DIR/db_$DATE.sql"

# Backup configuration et clés
tar -czf "$BACKUP_DIR/data_$DATE.tar.gz" data/

# Rotation (garder 30 jours)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup terminé: $BACKUP_DIR"
```

Ajoutez à crontab :
```bash
0 2 * * * /opt/rustdesk/backup-rustdesk.sh
```

### Mise à jour

```bash
# Pull nouvelles images
docker compose -f docker-compose.prod.yml pull

# Redémarrage progressif (zero-downtime avec HA)
docker compose -f docker-compose.prod.yml up -d --no-deps hbbr-secondary
sleep 30
docker compose -f docker-compose.prod.yml up -d --no-deps hbbr
sleep 30
docker compose -f docker-compose.prod.yml up -d --no-deps hbbs
```

## 🔍 Dépannage

### Problèmes courants

#### Clients ne peuvent pas se connecter

```bash
# Vérifier que les ports sont ouverts
netstat -tuln | grep -E "21115|21116|21117|21118|21119"

# Tester depuis une machine cliente
telnet rustdesk-office.bh-systems.be 21116
telnet rustdesk-office.bh-systems.be 21117

# Vérifier les logs
docker logs rustdesk-hbbs | tail -50
```

#### Mauvaises performances relay

```bash
# Vérifier la charge CPU/RAM
docker stats rustdesk-hbbr

# Voir la bande passante utilisée
iftop -i docker0

# Augmenter les ressources si nécessaire
# Éditer docker-compose.prod.yml:
#   resources:
#     limits:
#       cpus: '8'
#       memory: 8G
```

#### LDAP ne fonctionne pas

```bash
# Tester la connexion LDAP
ldapsearch -x -H ldap://ad-office.bh-systems.be:389 \
  -D "CN=RustDesk Service,OU=Service Accounts,DC=bh-systems,DC=be" \
  -w "mot_de_passe" \
  -b "DC=bh-systems,DC=be" "(objectClass=user)"

# Vérifier les logs API
docker logs rustdesk-api | grep LDAP
```

## 📝 Checklist de déploiement

### Avant le déploiement

- [ ] Serveurs provisionnés (CPU, RAM, Disque)
- [ ] IPs statiques assignées
- [ ] DNS configuré (rustdesk-office/mcn/sfn.bh-systems.be)
- [ ] Certificats SSL obtenus
- [ ] Comptes de service AD/LDAP créés
- [ ] Firewall rules documentées
- [ ] Plan de backup en place

### Après le déploiement

- [ ] Services démarrés et healthy
- [ ] Ports accessibles (tests telnet)
- [ ] Clé publique récupérée
- [ ] Monitoring configuré
- [ ] Logs centralisés
- [ ] Backup automatique configuré
- [ ] Tests de connexion client réussis
- [ ] Documentation à jour

## 📚 Références

- [Documentation RustDesk officielle](https://rustdesk.com/docs/)
- [Guide administrateur](../docs/ADMIN_GUIDE.md)
- [Guide utilisateur](../docs/USER_GUIDE.md)
- [Sécurité](../docs/SECURITY.md)

## 📞 Support

Pour toute question :
- GitHub Issues : https://github.com/boujrafh/rustdesk-remote-access-platform/issues
- Documentation : https://github.com/boujrafh/rustdesk-remote-access-platform/wiki
