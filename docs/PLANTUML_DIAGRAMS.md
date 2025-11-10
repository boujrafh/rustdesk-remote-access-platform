# Diagrammes d'Architecture RustDesk - PlantUML

Ce document contient les schémas d'architecture en **PlantUML**. 

## 📋 Installation et Utilisation

### Prérequis
```bash
# Installer PlantUML
# Option 1: Via package manager
sudo apt install plantuml  # Ubuntu/Debian
brew install plantuml      # macOS

# Option 2: Via Java
wget https://sourceforge.net/projects/plantuml/files/plantuml.jar/download -O plantuml.jar
java -jar plantuml.jar diagram.puml
```

### VS Code Extension
- Installer l'extension "PlantUML" par jebbs
- Prévisualisation: `Alt + D`
- Export PNG: Clic droit → "Export Current Diagram"

### Générer les images
```bash
# Générer tous les diagrammes
plantuml docs/plantuml/*.puml

# Générer en SVG
plantuml -tsvg docs/plantuml/*.puml
```

---

## 📊 1. Vue d'ensemble des 3 environnements

**Fichier:** `overview.puml`

\`\`\`plantuml
@startuml overview
!define AWSPUML https://raw.githubusercontent.com/awslabs/aws-icons-for-plantuml/v14.0/dist
!include AWSPUML/AWSCommon.puml
!include AWSPUML/NetworkingContentDelivery/VPC.puml
!include AWSPUML/SecurityIdentityCompliance/SecretsManager.puml
!include AWSPUML/Database/Database.puml

skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle

title Vue d'ensemble - Architecture RustDesk Multi-Environnements

cloud "Internet / VPN" as internet {
    component "VPN d'entreprise" as vpn
}

package "Environnement 1: Office + Industrial\n~4000 machines" as office #E1F5E1 {
    component "hbbs\n10.10.0.100" as hbbs1
    component "hbbr Primary\n10.10.0.101" as relay1a
    component "hbbr Secondary\n10.10.0.102" as relay1b
    database "PostgreSQL\nOffice" as db1
    
    hbbs1 --> relay1a : relay
    hbbs1 --> relay1b : backup
    relay1a ..> relay1b : failover
    hbbs1 --> db1
}

package "Environnement 2: MCN Sécurisé\n~2000 machines" as mcn #FFE1E1 {
    component "Firewall Strict\nPorts: 21115-21119" as fw2
    component "hbbs\n172.20.0.100" as hbbs2
    component "hbbr\n172.20.0.101" as relay2
    database "PostgreSQL\nMCN" as db2
    
    fw2 --> hbbs2
    hbbs2 --> relay2
    hbbs2 --> db2
}

package "Environnement 3: SFN Sécurisé\n~2000 machines" as sfn #FFE1E1 {
    component "Firewall Strict\nPorts: 21115-21119" as fw3
    component "hbbs\n172.30.0.100" as hbbs3
    component "hbbr\n172.30.0.101" as relay3
    database "PostgreSQL\nSFN" as db3
    
    fw3 --> hbbs3
    hbbs3 --> relay3
    hbbs3 --> db3
}

vpn --> office
vpn --> mcn
vpn --> sfn

note right of office
  Domaine: rustdesk-office.bh-systems.be
  LDAP: ad-office.bh-systems.be
  Subnet: 10.10.0.0/16
end note

note right of mcn
  Domaine: rustdesk-mcn.bh-systems.be
  LDAP: ad-mcn.bh-systems.be
  Subnet: 172.20.0.0/16
  Sécurité: MAXIMALE
end note

note right of sfn
  Domaine: rustdesk-sfn.bh-systems.be
  LDAP: ad-sfn.bh-systems.be
  Subnet: 172.30.0.0/16
  Sécurité: MAXIMALE
end note

@enduml
\`\`\`

---

## 🏗️ 2. Architecture détaillée - Environnement Office

**Fichier:** `office-detailed.puml`

\`\`\`plantuml
@startuml office-detailed
skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle
skinparam monochrome false

title Architecture Détaillée - Environnement Office (~4000 machines)

actor "Client 1" as c1
actor "Client 2" as c2
actor "Client ..." as c3
actor "Client 4000" as c4

package "ID/Rendezvous Server" as id_server #E1F5E1 {
    component "hbbs\n10.10.0.100\nPort 21116" as hbbs
    database "SQLite\nPeer DB" as sqlite
    hbbs --> sqlite
}

package "Load Balancing" as lb_pkg #FFF4E1 {
    component "Auto-sélection\nmeilleur relay" as lb
}

package "Relay Cluster" as relay_cluster #FFE1E1 {
    component "hbbr Primary\n10.10.0.101\nPort 21117" as relay1
    component "hbbr Secondary\n10.10.0.102\nPort 21117" as relay2
    
    relay1 ..> relay2 : failover
}

package "Backend Services" as backend #E1E5FF {
    component "Nginx\nHTTPS/SSL" as nginx
    component "API Server\nPort 21114" as api
    database "PostgreSQL\nUser/Auth" as postgres
    database "Redis\nCache" as redis
    
    nginx --> api
    api --> postgres
    api --> redis
}

package "Active Directory" as ad #FFE1F0 {
    component "LDAP Server\nad-office.bh-systems.be" as ldap
}

c1 --> hbbs
c2 --> hbbs
c3 --> hbbs
c4 --> hbbs

hbbs --> lb
lb --> relay1
lb --> relay2

hbbs --> api
api --> ldap

note right of relay_cluster
  Ressources par relay:
  - 4 vCPU
  - 4 GB RAM
  - 1 Gbps bandwidth
  
  Capacité totale:
  - ~2000 connexions/relay
  - Bande passante: 2 Gbps
end note

note bottom of backend
  SSL/TLS: Certificats Let's Encrypt
  API: Authentification JWT
  Cache: Session + Rate limiting
end note

@enduml
\`\`\`

---

## 🔒 3. Architecture Sécurisée - MCN/SFN

**Fichier:** `secured-mcn-sfn.puml`

\`\`\`plantuml
@startuml secured-mcn-sfn
skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle

title Architecture Sécurisée - MCN/SFN (Réseaux Canalisés)

cloud "Réseau externe" as external {
    actor "Tentatives\nconnexion\nexternes" as attacker
}

package "Firewall (iptables/Windows)" as firewall #FF6B6B {
    component "Règles strictes" as rules
    
    note right of rules
      ✅ AUTORISÉ:
      - 21115 TCP (NAT test)
      - 21116 TCP/UDP (Registration)
      - 21117 TCP (Relay)
      - 21118 TCP (WebSocket)
      - 21119 TCP (WebSocket)
      
      ❌ BLOQUÉ:
      - Tout le reste
      - SSH limité au réseau admin
    end note
}

package "Zone Sécurisée MCN/SFN" as dmz #FFE1E1 {
    component "hbbs\n172.20.0.100 / 172.30.0.100" as hbbs
    component "hbbr\n172.20.0.101 / 172.30.0.101" as relay
    
    hbbs --> relay
}

package "Audit & Monitoring" as monitoring #FFF4E1 {
    component "Logs détaillés\n/var/log/rustdesk/audit.log" as logs
    component "Alertes de sécurité" as alerts
    
    hbbs --> logs
    relay --> logs
    logs --> alerts
}

package "Authentification" as auth #E1F0FF {
    component "AD MCN/SFN\nSéparé d'Office" as ad
    component "Groupes autorisés\nMCN-Admins / SFN-Admins" as groups
    
    ad --> groups
}

attacker .down.> rules : bloqué
rules --> hbbs : filtré
rules --> relay : filtré

hbbs --> auth

note bottom of monitoring
  Audit complet:
  - Toutes les connexions loggées
  - Tentatives échouées
  - Changements de configuration
  - Alertes temps réel
end note

@enduml
\`\`\`

---

## 📡 4. Flux de connexion RustDesk (Séquence)

**Fichier:** `connection-flow.puml`

\`\`\`plantuml
@startuml connection-flow
skinparam backgroundColor #FEFEFE
skinparam sequenceMessageAlign center

title Flux de Connexion RustDesk - P2P et Relay

participant "Client 1" as c1
participant "Client 2" as c2
participant "hbbs\n(ID Server)" as hbbs
participant "hbbr\n(Relay)" as relay
database "Database" as db

== Phase 1: Enregistrement ==

c1 -> hbbs : Connexion (port 21116)
activate hbbs
hbbs -> db : Enregistrer ID client
hbbs --> c1 : ID attribué (123456789)
deactivate hbbs

c2 -> hbbs : Connexion (port 21116)
activate hbbs
hbbs -> db : Enregistrer ID client
hbbs --> c2 : ID attribué (987654321)
deactivate hbbs

== Phase 2: Tentative P2P directe ==

c1 -> hbbs : Demande connexion à 987654321
activate hbbs
hbbs -> c1 : Info C2 (IP, port)
hbbs -> c2 : C1 veut se connecter
deactivate hbbs

c1 -> c2 : Tentative connexion directe P2P

alt P2P réussie (pas de NAT)
    c1 <-> c2 : **Connexion P2P établie**
    note over c1,c2
      Flux direct entre clients
      Performance OPTIMALE
      Pas de charge sur relay
    end note
    
else P2P échouée (NAT/Firewall)
    c1 -> hbbs : P2P échoué, besoin relay
    activate hbbs
    hbbs -> relay : Activer relay pour session
    deactivate hbbs
    
    == Phase 3: Relay ==
    
    c1 -> relay : Connexion relay (port 21117)
    activate relay
    c2 -> relay : Connexion relay (port 21117)
    
    relay -> c1 : Flux vidéo/données
    relay -> c2 : Flux vidéo/données
    
    note over relay
      Relay actif
      Bande passante consommée
      Performance dégradée vs P2P
    end note
    deactivate relay
end

@enduml
\`\`\`

---

## 🔄 5. Haute Disponibilité - Failover Relay

**Fichier:** `ha-failover.puml`

\`\`\`plantuml
@startuml ha-failover
skinparam backgroundColor #FEFEFE

title Haute Disponibilité - Failover Automatique des Relays

[*] --> Normal

state Normal {
    state "Primary Relay ACTIF\nSecondary en Standby" as primary_active
    
    note right of primary_active
      ✅ Primary: 100% charge
      ⏸️ Secondary: 0% charge
      Health check: 30s
    end note
}

state "Health Check" as check

state Degraded {
    state "Primary DOWN détecté" as primary_down
    
    note right of primary_down
      ❌ Primary: unreachable
      ⚠️ Basculement imminent
    end note
}

state Failover {
    state "Basculement en cours" as switching
    
    note right of switching
      🔄 Redirection clients
      ⏱️ Durée: ~5 secondes
    end note
}

state SecondaryActive {
    state "Secondary Relay ACTIF\nPrimary arrêté" as secondary_active
    
    note right of secondary_active
      ⏸️ Primary: 0% (DOWN)
      ✅ Secondary: 100% charge
      Monitoring Primary: 30s
    end note
}

state Recovering {
    state "Primary revenu\nRetour progressif" as recovering
    
    note right of recovering
      ⚡ Load balancing 50/50
      📈 Puis 100% Primary
      ⏱️ Durée: ~60 secondes
    end note
}

Normal --> check : Timer (30s)
check --> Normal : Primary OK
check --> Degraded : Primary DOWN

Degraded --> Failover : Auto-trigger
Failover --> SecondaryActive : Basculement complet

SecondaryActive --> SecondaryActive : Primary toujours DOWN
SecondaryActive --> Recovering : Primary revenu (UP)

Recovering --> Normal : Retour complet

@enduml
\`\`\`

---

## 🌐 6. Déploiement Homeworking/VPN

**Fichier:** `vpn-deployment.puml`

\`\`\`plantuml
@startuml vpn-deployment
skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle

title Déploiement Homeworking via VPN

actor "Utilisateur\nà domicile" as user
node "Laptop avec\nVPN Client" as laptop

cloud "Internet" as internet {
    component "FAI" as isp
}

package "VPN d'entreprise" as vpn #FFE1E1 {
    component "VPN Gateway\nOpenVPN/IPSec" as vpn_gw
    component "Règles réseau" as vpn_rules
    
    note right of vpn_rules
      Accès selon droits:
      ✅ Office: Tous les employés
      🔒 MCN: Admins MCN uniquement
      🔐 SFN: Admins SFN uniquement
    end note
}

package "Réseau d'entreprise" as enterprise {
    
    package "Office Network\n10.10.0.0/16" as office_net #E1F5E1 {
        component "RustDesk Office\n10.10.0.100" as rd_office
    }
    
    package "MCN Network\n172.20.0.0/16" as mcn_net #FFE1E1 {
        component "RustDesk MCN\n172.20.0.100" as rd_mcn
    }
    
    package "SFN Network\n172.30.0.0/16" as sfn_net #FFE1E1 {
        component "RustDesk SFN\n172.30.0.100" as rd_sfn
    }
}

user --> laptop
laptop --> isp
isp --> vpn_gw
vpn_gw --> vpn_rules

vpn_rules --> rd_office : Droits Office
vpn_rules --> rd_mcn : Droits MCN
vpn_rules --> rd_sfn : Droits SFN

note bottom of enterprise
  Après connexion VPN, l'utilisateur
  peut accéder aux serveurs RustDesk
  selon ses permissions AD/LDAP
end note

@enduml
\`\`\`

---

## 📦 7. Architecture Docker - Production

**Fichier:** `docker-architecture.puml`

\`\`\`plantuml
@startuml docker-architecture
skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle

title Architecture Docker - Production

node "Docker Host" as host {
    
    package "Network: rustdesk-network\n172.21.0.0/24" as network {
        
        component "Container: hbbs" as hbbs_container #E1F5E1 {
            component "Process: hbbs\n-r relay:21117" as hbbs_proc
            storage "/root/data\nSQLite + Keys" as hbbs_vol
        }
        
        component "Container: hbbr" as relay_container #FFF4E1 {
            component "Process: hbbr\n-k _" as relay_proc
            storage "/root/data\nShared Keys" as relay_vol
        }
        
        component "Container: nginx" as nginx_container #E1E5FF {
            component "Nginx" as nginx_proc
            storage "/etc/nginx/certs\nSSL Certificates" as ssl_certs
        }
        
        component "Container: postgres" as pg_container #FFE1F0 {
            component "PostgreSQL 15" as pg_proc
            storage "/var/lib/postgresql/data" as pg_data
        }
        
        component "Container: api" as api_container #F0E1FF {
            component "API Server" as api_proc
            storage "/data" as api_data
        }
        
        hbbs_proc --> relay_proc : relay
        nginx_proc --> api_proc : proxy
        api_proc --> pg_proc : database
    }
}

package "Ports exposés sur host" as ports {
    component "21115:21115 TCP" as p21115
    component "21116:21116 TCP/UDP" as p21116
    component "21117:21117 TCP" as p21117
    component "443:443 HTTPS" as p443
}

hbbs_container --> p21115
hbbs_container --> p21116
relay_container --> p21117
nginx_container --> p443

note right of network
  Subnet isolé Docker
  Gateway: 172.21.0.1
  
  IPs fixes:
  - hbbs: .10
  - hbbr: .11
  - nginx: .12
end note

note bottom of ports
  Mapping des ports:
  - 21115: NAT test
  - 21116: ID registration
  - 21117: Relay traffic
  - 443: API HTTPS
end note

@enduml
\`\`\`

---

## 📊 8. Scaling et métriques de charge

**Fichier:** `scaling-metrics.puml`

\`\`\`plantuml
@startuml scaling-metrics
skinparam backgroundColor #FEFEFE

title Métriques de Scaling - RustDesk

package "Configuration selon charge" {
    
    card "1-100 machines" as m1 #90EE90 {
        component "1 serveur unique\nhbbs + hbbr" as s1
        note bottom
          ✅ Configuration OK
          2 vCPU, 2 GB RAM
        end note
    }
    
    card "100-500 machines" as m2 #FFD700 {
        component "Relay séparé\nRECOMMANDÉ" as s2a
        component "hbbs: 2 vCPU, 2 GB" as s2b
        component "hbbr: 4 vCPU, 4 GB" as s2c
        s2a --> s2b
        s2a --> s2c
    }
    
    card "500-2000 machines" as m3 #FFA500 {
        component "Relay séparé\nOBLIGATOIRE" as s3a
        component "hbbs: 2 vCPU, 4 GB" as s3b
        component "hbbr: 4 vCPU, 8 GB" as s3c
        s3a --> s3b
        s3a --> s3c
        note bottom
          ⚠️ Performances dégradées
          si serveur unique
        end note
    }
    
    card "2000-8000 machines" as m4 #FF6347 {
        component "Multiple relays\n+ HA" as s4a
        component "hbbs: 4 vCPU, 8 GB" as s4b
        component "hbbr-1: 8 vCPU, 16 GB" as s4c
        component "hbbr-2: 8 vCPU, 16 GB" as s4d
        s4a --> s4b
        s4a --> s4c
        s4a --> s4d
        s4c ..> s4d : failover
        note bottom
          🔴 HA requis
          Load balancing
        end note
    }
    
    card "8000+ machines" as m5 #DC143C {
        component "Cluster\n+ Load Balancer" as s5
        note bottom
          🔴🔴 Architecture cluster
          Multiple hbbs + hbbr
          Load balancer externe
        end note
    }
}

@enduml
\`\`\`

---

## 🔐 9. Authentification LDAP (Séquence)

**Fichier:** `ldap-auth-flow.puml`

\`\`\`plantuml
@startuml ldap-auth-flow
skinparam backgroundColor #FEFEFE
skinparam sequenceMessageAlign center

title Flux d'Authentification LDAP/Active Directory

actor "👤 Utilisateur" as user
participant "RustDesk\nClient" as client
participant "hbbs\nServer" as hbbs
participant "API\nServer" as api
participant "AD/LDAP\nServer" as ldap
database "PostgreSQL" as db

user -> client : Lancement RustDesk
activate client

client -> hbbs : Connexion (ID + Password)
activate hbbs

hbbs -> api : Vérifier authentification
activate api

api -> ldap : LDAP Bind (username/password)
activate ldap

alt Authentification réussie
    ldap --> api : ✅ OK + Groupes utilisateur
    deactivate ldap
    
    api -> api : Vérifier groupes autorisés\n(MCN-Admins / SFN-Admins)
    
    alt Groupe autorisé
        api -> db : Enregistrer session
        activate db
        db --> api : Session ID
        deactivate db
        
        api --> hbbs : ✅ Authentification OK
        deactivate api
        
        hbbs --> client : ✅ Connexion établie
        deactivate hbbs
        
        client --> user : ✅ Accès autorisé
        deactivate client
        
    else Groupe non autorisé
        api --> hbbs : ❌ Accès refusé
        deactivate api
        hbbs --> client : ❌ Permissions insuffisantes
        deactivate hbbs
        client --> user : ❌ Accès refusé
        deactivate client
    end
    
else Authentification échouée
    ldap --> api : ❌ Erreur
    deactivate ldap
    
    api --> hbbs : ❌ Auth failed
    deactivate api
    
    hbbs --> client : ❌ Identifiants invalides
    deactivate hbbs
    
    client --> user : ❌ Login/mot de passe incorrect
    deactivate client
end

note over ldap,db
  📝 Audit complet:
  Toutes les tentatives de connexion
  (réussies et échouées) sont loggées
  pour traçabilité sécurité
end note

@enduml
\`\`\`

---

## 🔧 10. Déploiement complet (Component)

**Fichier:** `full-deployment.puml`

\`\`\`plantuml
@startuml full-deployment
skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle

title Déploiement Complet - Production

package "Clients (~8000 machines)" {
    [Client Windows 1..2000] as win
    [Client Linux 1..2000] as linux
    [Client macOS 1..2000] as mac
    [Homeworking via VPN 1..2000] as vpn_clients
}

package "Load Balancer / DNS" as lb_layer #E1E5FF {
    [DNS Round Robin] as dns
    [Health Check] as health
}

package "Environnement Office" as office_env #E1F5E1 {
    component "hbbs Office" as hbbs_office {
        [Port 21115-21116]
    }
    
    component "Relay Cluster" as relay_office {
        [hbbr Primary\n10.10.0.101]
        [hbbr Secondary\n10.10.0.102]
    }
    
    database "PostgreSQL\nOffice" as db_office
    database "Redis\nCache" as redis_office
}

package "Environnement MCN" as mcn_env #FFE1E1 {
    component "Firewall MCN" as fw_mcn
    component "hbbs MCN" as hbbs_mcn
    component "hbbr MCN" as relay_mcn
    database "PostgreSQL\nMCN" as db_mcn
}

package "Environnement SFN" as sfn_env #FFE1E1 {
    component "Firewall SFN" as fw_sfn
    component "hbbs SFN" as hbbs_sfn
    component "hbbr SFN" as relay_sfn
    database "PostgreSQL\nSFN" as db_sfn
}

package "Active Directory" as ad_layer #FFE1F0 {
    [AD Office] as ad_office
    [AD MCN] as ad_mcn
    [AD SFN] as ad_sfn
}

package "Monitoring & Backup" as monitoring #FFF4E1 {
    [Prometheus/Grafana] as metrics
    [Logs centralisés\nELK Stack] as logs
    [Backup automatique] as backup
}

win --> dns
linux --> dns
mac --> dns
vpn_clients --> dns

dns --> health
health --> hbbs_office
health --> hbbs_mcn
health --> hbbs_sfn

hbbs_office --> relay_office
hbbs_office --> db_office
hbbs_office --> redis_office
hbbs_office --> ad_office

fw_mcn --> hbbs_mcn
hbbs_mcn --> relay_mcn
hbbs_mcn --> db_mcn
hbbs_mcn --> ad_mcn

fw_sfn --> hbbs_sfn
hbbs_sfn --> relay_sfn
hbbs_sfn --> db_sfn
hbbs_sfn --> ad_sfn

hbbs_office --> metrics
hbbs_mcn --> metrics
hbbs_sfn --> metrics

hbbs_office --> logs
hbbs_mcn --> logs
hbbs_sfn --> logs

db_office --> backup
db_mcn --> backup
db_sfn --> backup

note right of monitoring
  Monitoring temps réel:
  - Clients connectés
  - Bande passante utilisée
  - CPU/RAM des serveurs
  - Logs d'audit sécurité
  
  Backup quotidien:
  - Bases de données
  - Configuration
  - Clés chiffrement
end note

@enduml
\`\`\`

---

## 📝 Utilisation de PlantUML

### Générer les diagrammes localement

```bash
# Créer le dossier pour les fichiers .puml
mkdir -p docs/plantuml

# Copier le contenu de chaque diagramme dans des fichiers .puml
# Exemple: docs/plantuml/overview.puml

# Générer les PNG
plantuml docs/plantuml/*.puml

# Générer les SVG (meilleure qualité)
plantuml -tsvg docs/plantuml/*.puml
```

### Intégration dans la documentation

```markdown
# Dans README.md ou autre doc

## Architecture Overview
![Architecture Overview](docs/plantuml/overview.png)

## Office Environment
![Office](docs/plantuml/office-detailed.png)
```

### Serveur PlantUML en ligne

```markdown
<!-- Utiliser le serveur PlantUML public -->
![Diagram](http://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/boujrafh/rustdesk-remote-access-platform/main/docs/plantuml/overview.puml)
```

### VS Code - Prévisualisation en temps réel

1. Installer l'extension "PlantUML" (jebbs)
2. Ouvrir un fichier `.puml`
3. Appuyer sur `Alt + D` pour la prévisualisation
4. Les modifications s'affichent en temps réel

---

## 🎨 Personnalisation

### Thèmes disponibles

```plantuml
@startuml
!theme cerulean
' ou
!theme blueprint
!theme carbon-gray
!theme mars
!theme metal
@enduml
```

### Couleurs personnalisées

```plantuml
skinparam backgroundColor #FEFEFE
skinparam component {
    BackgroundColor #E1F5E1
    BorderColor #2E7D32
    FontColor #1B5E20
}
```

---

## 📚 Références

- [PlantUML Official](https://plantuml.com/)
- [PlantUML Online Server](http://www.plantuml.com/plantuml/)
- [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=jebbs.plantuml)
- [PlantUML Cheat Sheet](https://plantuml.com/guide)
- [AWS Icons for PlantUML](https://github.com/awslabs/aws-icons-for-plantuml)
