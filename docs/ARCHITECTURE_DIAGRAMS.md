# Diagrammes d'Architecture RustDesk

Ce document contient les schémas d'architecture pour le déploiement RustDesk multi-environnements.

## 📊 Vue d'ensemble des 3 environnements

```mermaid
graph TB
    subgraph Internet["🌐 Internet / VPN"]
        VPN[VPN d'entreprise]
    end
    
    subgraph Office["🏢 Environnement 1: Office + Industrial<br/>~4000 machines"]
        HBBS1[hbbs<br/>10.10.0.100<br/>ID/Rendezvous]
        RELAY1A[hbbr Primary<br/>10.10.0.101<br/>Relay Server]
        RELAY1B[hbbr Secondary<br/>10.10.0.102<br/>Backup]
        DB1[(PostgreSQL<br/>Office)]
        
        HBBS1 --> RELAY1A
        HBBS1 --> RELAY1B
        RELAY1A -.backup.-> RELAY1B
        HBBS1 --> DB1
    end
    
    subgraph MCN["🔒 Environnement 2: MCN Sécurisé<br/>~2000 machines"]
        FW2[Firewall Strict<br/>Ports: 21115-21119]
        HBBS2[hbbs<br/>172.20.0.100]
        RELAY2[hbbr<br/>172.20.0.101]
        DB2[(PostgreSQL<br/>MCN)]
        
        FW2 --> HBBS2
        HBBS2 --> RELAY2
        HBBS2 --> DB2
    end
    
    subgraph SFN["🔐 Environnement 3: SFN Sécurisé<br/>~2000 machines"]
        FW3[Firewall Strict<br/>Ports: 21115-21119]
        HBBS3[hbbs<br/>172.30.0.100]
        RELAY3[hbbr<br/>172.30.0.101]
        DB3[(PostgreSQL<br/>SFN)]
        
        FW3 --> HBBS3
        HBBS3 --> RELAY3
        HBBS3 --> DB3
    end
    
    VPN --> Office
    VPN --> MCN
    VPN --> SFN
    
    style Office fill:#e1f5e1
    style MCN fill:#ffe1e1
    style SFN fill:#ffe1e1
    style Internet fill:#e1e5ff
```

## 🏗️ Architecture détaillée - Environnement Office

```mermaid
graph LR
    subgraph Clients["👥 Clients Office + Industrial<br/>~4000 machines"]
        C1[Client 1]
        C2[Client 2]
        C3[Client ...]
        C4[Client 4000]
    end
    
    subgraph LoadBalancer["⚖️ Load Balancing"]
        LB[Auto-sélection<br/>meilleur relay]
    end
    
    subgraph IDServer["🆔 ID/Rendezvous Server"]
        HBBS[hbbs<br/>10.10.0.100<br/>Port 21116]
        HBBS_DB[(SQLite<br/>Peer DB)]
        HBBS --> HBBS_DB
    end
    
    subgraph RelayCluster["🔄 Relay Cluster"]
        RELAY1[hbbr Primary<br/>10.10.0.101<br/>Port 21117]
        RELAY2[hbbr Secondary<br/>10.10.0.102<br/>Port 21117]
        
        RELAY1 -.failover.-> RELAY2
    end
    
    subgraph Backend["💾 Backend Services"]
        NGINX[Nginx<br/>HTTPS/SSL]
        API[API Server<br/>Port 21114]
        PG[(PostgreSQL<br/>User/Auth)]
        REDIS[(Redis<br/>Cache)]
        
        NGINX --> API
        API --> PG
        API --> REDIS
    end
    
    subgraph AD["🔐 Active Directory"]
        LDAP[LDAP Server<br/>ad-office.bh-systems.be]
    end
    
    C1 --> HBBS
    C2 --> HBBS
    C3 --> HBBS
    C4 --> HBBS
    
    HBBS --> LB
    LB --> RELAY1
    LB --> RELAY2
    
    HBBS --> API
    API --> LDAP
    
    style IDServer fill:#e1f5e1
    style RelayCluster fill:#fff4e1
    style Backend fill:#e1e5ff
    style AD fill:#ffe1f0
```

## 🔒 Architecture Sécurisée - MCN/SFN

```mermaid
graph TB
    subgraph External["🌐 Réseau externe"]
        EXT[Tentatives de<br/>connexion externes]
    end
    
    subgraph Firewall["🛡️ Firewall (iptables/Windows Firewall)"]
        FW_RULES["Règles strictes:<br/>✅ 21115 TCP<br/>✅ 21116 TCP/UDP<br/>✅ 21117 TCP<br/>✅ 21118 TCP<br/>✅ 21119 TCP<br/>❌ Tout le reste BLOQUÉ"]
    end
    
    subgraph DMZ["🔐 Zone Sécurisée MCN/SFN"]
        HBBS[hbbs<br/>172.20.0.100 / 172.30.0.100]
        RELAY[hbbr<br/>172.20.0.101 / 172.30.0.101]
        
        HBBS --> RELAY
    end
    
    subgraph Monitoring["📊 Audit & Monitoring"]
        LOGS[Logs détaillés<br/>/var/log/rustdesk/audit.log]
        ALERT[Alertes de sécurité]
        
        HBBS --> LOGS
        RELAY --> LOGS
        LOGS --> ALERT
    end
    
    subgraph Auth["🔑 Authentification"]
        AD_MCN[AD MCN/SFN<br/>Séparé d'Office]
        GROUPS[Groupes autorisés<br/>MCN-Admins / SFN-Admins]
        
        AD_MCN --> GROUPS
    end
    
    EXT -.bloqué.-> FW_RULES
    FW_RULES --> HBBS
    FW_RULES --> RELAY
    
    HBBS --> Auth
    
    style Firewall fill:#ff6b6b
    style DMZ fill:#ffe1e1
    style Monitoring fill:#fff4e1
    style Auth fill:#e1f0ff
```

## 📡 Flux de connexion RustDesk

```mermaid
sequenceDiagram
    participant C1 as Client 1
    participant C2 as Client 2
    participant HBBS as hbbs (ID Server)
    participant RELAY as hbbr (Relay)
    participant DB as Database
    
    Note over C1,C2: Phase 1: Enregistrement
    C1->>HBBS: Connexion (port 21116)
    HBBS->>DB: Enregistrer ID client
    HBBS->>C1: ID attribué (ex: 123456789)
    
    C2->>HBBS: Connexion (port 21116)
    HBBS->>DB: Enregistrer ID client
    HBBS->>C2: ID attribué (ex: 987654321)
    
    Note over C1,C2: Phase 2: Tentative P2P directe
    C1->>HBBS: Demande connexion à 987654321
    HBBS->>C1: Info C2 (IP, port)
    HBBS->>C2: C1 veut se connecter
    
    C1->>C2: Tentative connexion directe
    
    alt P2P réussie (pas de NAT)
        C1->>C2: Connexion P2P établie
        Note over C1,C2: Flux direct (optimal)
    else P2P échouée (NAT/Firewall)
        Note over C1,RELAY: Phase 3: Relay
        C1->>HBBS: P2P échoué
        HBBS->>RELAY: Activer relay
        C1->>RELAY: Connexion relay (port 21117)
        C2->>RELAY: Connexion relay (port 21117)
        RELAY->>C1: Flux vidéo/données
        RELAY->>C2: Flux vidéo/données
        Note over C1,C2: Flux via relay (backup)
    end
```

## 🔄 Haute Disponibilité - Failover Relay

```mermaid
stateDiagram-v2
    [*] --> Normal
    
    Normal --> CheckHealth: Health check (30s)
    
    CheckHealth --> Normal: Primary OK
    CheckHealth --> Degraded: Primary DOWN
    
    Degraded --> Failover: Basculement auto
    Failover --> SecondaryActive: Relay Secondary actif
    
    SecondaryActive --> CheckPrimary: Health check Primary
    CheckPrimary --> SecondaryActive: Primary toujours DOWN
    CheckPrimary --> Recovering: Primary revenu
    
    Recovering --> Normal: Basculement vers Primary
    
    note right of Normal
        ✅ Primary Relay actif
        ⏸️ Secondary en standby
        Charge: 100% sur Primary
    end note
    
    note right of SecondaryActive
        ⏸️ Primary inactif
        ✅ Secondary actif
        Charge: 100% sur Secondary
    end note
    
    note right of Recovering
        ⚠️ Retour progressif
        Load balancing 50/50
        puis 100% Primary
    end note
```

## 🌐 Déploiement HomeworkingVPN

```mermaid
graph TB
    subgraph Home["🏠 Télétravail"]
        USER[Utilisateur<br/>à domicile]
        LAPTOP[Laptop avec<br/>VPN Client]
    end
    
    subgraph Internet["☁️ Internet"]
        ISP[FAI]
    end
    
    subgraph VPN["🔐 VPN d'entreprise"]
        VPN_GW[VPN Gateway<br/>OpenVPN/IPSec]
        VPN_RULES["Règles réseau:<br/>✅ Accès Office/MCN/SFN<br/>selon droits utilisateur"]
    end
    
    subgraph Enterprise["🏢 Réseau d'entreprise"]
        direction TB
        
        subgraph Office_Net["Office Network<br/>10.10.0.0/16"]
            RD_OFFICE[RustDesk Office<br/>10.10.0.100]
        end
        
        subgraph MCN_Net["MCN Network<br/>172.20.0.0/16"]
            RD_MCN[RustDesk MCN<br/>172.20.0.100]
        end
        
        subgraph SFN_Net["SFN Network<br/>172.30.0.0/16"]
            RD_SFN[RustDesk SFN<br/>172.30.0.100]
        end
    end
    
    USER --> LAPTOP
    LAPTOP --> ISP
    ISP --> VPN_GW
    VPN_GW --> VPN_RULES
    
    VPN_RULES -->|Droits Office| RD_OFFICE
    VPN_RULES -->|Droits MCN| RD_MCN
    VPN_RULES -->|Droits SFN| RD_SFN
    
    style Home fill:#e1f5e1
    style VPN fill:#ffe1e1
    style Enterprise fill:#e1e5ff
```

## 📦 Architecture Docker - Production

```mermaid
graph TB
    subgraph DockerHost["🐳 Docker Host"]
        subgraph Network["rustdesk-network (172.21.0.0/24)"]
            
            subgraph Container1["📦 Container: hbbs"]
                HBBS_PROC[Process: hbbs<br/>-r relay:21117]
                HBBS_VOL[/root/data<br/>SQLite DB + Keys]
            end
            
            subgraph Container2["📦 Container: hbbr"]
                RELAY_PROC[Process: hbbr<br/>-k _]
                RELAY_VOL[/root/data<br/>Shared Keys]
            end
            
            subgraph Container3["📦 Container: nginx"]
                NGINX_PROC[Nginx]
                SSL_CERTS[/etc/nginx/certs<br/>SSL Certificates]
            end
            
            subgraph Container4["📦 Container: postgres"]
                PG_PROC[PostgreSQL 15]
                PG_DATA[/var/lib/postgresql/data]
            end
            
            subgraph Container5["📦 Container: api"]
                API_PROC[API Server]
                API_DATA[/data]
            end
            
        end
    end
    
    subgraph HostPorts["🔌 Ports exposés"]
        P21115[21115:21115 TCP]
        P21116[21116:21116 TCP/UDP]
        P21117[21117:21117 TCP]
        P443[443:443 HTTPS]
    end
    
    HBBS_PROC --> RELAY_PROC
    NGINX_PROC --> API_PROC
    API_PROC --> PG_PROC
    
    Container1 --> P21115
    Container1 --> P21116
    Container2 --> P21117
    Container3 --> P443
    
    style Container1 fill:#e1f5e1
    style Container2 fill:#fff4e1
    style Container3 fill:#e1e5ff
    style Container4 fill:#ffe1f0
    style Container5 fill:#f0e1ff
```

## 📊 Charge et Scaling

```mermaid
graph LR
    subgraph Metrics["📊 Métriques de charge"]
        M1[1-100 machines<br/>1 serveur unique OK]
        M2[100-500 machines<br/>Relay séparé recommandé]
        M3[500-2000 machines<br/>Relay séparé OBLIGATOIRE]
        M4[2000-8000 machines<br/>Multiple relays + HA]
        M5[8000+ machines<br/>Cluster + Load Balancer]
    end
    
    subgraph Config1["Configuration 1 serveur"]
        S1[hbbs + hbbr<br/>même machine]
        S1_RAM[2 GB RAM]
        S1_CPU[2 vCPU]
    end
    
    subgraph Config2["Configuration séparée"]
        S2A[hbbs<br/>machine 1]
        S2B[hbbr<br/>machine 2]
        S2A_RAM[2 GB RAM]
        S2B_RAM[4 GB RAM]
    end
    
    subgraph Config3["Configuration HA"]
        S3A[hbbs]
        S3B[hbbr primary]
        S3C[hbbr secondary]
        S3_LB[Load Balancer]
    end
    
    M1 --> Config1
    M2 --> Config2
    M3 --> Config2
    M4 --> Config3
    M5 --> Config3
    
    style M1 fill:#90EE90
    style M2 fill:#FFD700
    style M3 fill:#FFA500
    style M4 fill:#FF6347
    style M5 fill:#DC143C
```

## 🔐 Sécurité - Flux d'authentification LDAP

```mermaid
sequenceDiagram
    participant User as 👤 Utilisateur
    participant Client as RustDesk Client
    participant HBBS as hbbs Server
    participant API as API Server
    participant LDAP as AD/LDAP Server
    participant DB as PostgreSQL
    
    User->>Client: Lancement RustDesk
    Client->>HBBS: Connexion (ID + Password)
    
    HBBS->>API: Vérifier authentification
    API->>LDAP: LDAP Bind (username/password)
    
    alt Authentification réussie
        LDAP->>API: OK + Groupes utilisateur
        API->>API: Vérifier groupes autorisés<br/>(MCN-Admins / SFN-Admins)
        
        alt Groupe autorisé
            API->>DB: Enregistrer session
            API->>HBBS: Authentification OK
            HBBS->>Client: Connexion établie
            Client->>User: ✅ Accès autorisé
        else Groupe non autorisé
            API->>HBBS: Accès refusé
            HBBS->>Client: Erreur: Permissions insuffisantes
            Client->>User: ❌ Accès refusé
        end
        
    else Authentification échouée
        LDAP->>API: Erreur
        API->>HBBS: Auth failed
        HBBS->>Client: Erreur: Identifiants invalides
        Client->>User: ❌ Login/mot de passe incorrect
    end
    
    Note over LDAP,DB: Audit: Toutes les tentatives<br/>sont loggées pour sécurité
```

---

## 📝 Utilisation des diagrammes

Ces diagrammes sont en **Mermaid** et s'affichent automatiquement sur GitHub, GitLab, et dans VS Code avec l'extension Mermaid.

### Modifier un diagramme

1. Éditez le code Mermaid entre les balises ` ```mermaid ` et ` ``` `
2. Prévisualisez dans VS Code (Ctrl+Shift+V)
3. Committez sur GitHub pour voir le rendu final

### Exporter en PNG/SVG

- **GitHub** : Cliquez sur le diagramme → bouton "Download SVG"
- **VS Code** : Extension "Mermaid Editor" → Export
- **En ligne** : https://mermaid.live

## 🔗 Références

- [Documentation Mermaid](https://mermaid.js.org/)
- [Mermaid Live Editor](https://mermaid.live)
- [GitHub Mermaid Support](https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/)
