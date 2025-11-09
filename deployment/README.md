# Guide de Déploiement RustDesk

Scripts de déploiement automatique pour Windows, Linux et macOS.

## 📋 Prérequis

- Serveur RustDesk déployé et fonctionnel
- Clé publique du serveur (fichier `data/id_ed25519.pub`)
- Privilèges administrateur sur les machines cibles

## 🔑 Obtenir la clé publique

### Développement
```bash
cat data/id_ed25519.pub
# ou sur Windows PowerShell
Get-Content .\data\id_ed25519.pub
```

La clé par défaut en dev est : `zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=`

### Production
```bash
# Sur le serveur de production
docker exec rustdesk-hbbs cat /root/id_ed25519.pub
```

## 💻 Windows

### Installation en développement (localhost)

```powershell
# Exécuter en tant qu'administrateur
.\deployment\deploy-windows.ps1 -Environment dev
```

### Installation en production

```powershell
# Exécuter en tant qu'administrateur
.\deployment\deploy-windows.ps1 `
    -ServerDomain "rustdesk.bh-systems.be" `
    -PublicKey "votre_cle_publique_ici" `
    -Environment prod
```

### Déploiement via GPO (Group Policy)

Pour déployer sur plusieurs machines Windows via Active Directory :

1. Copiez `deploy-windows.ps1` sur un partage réseau
2. Créez une GPO avec un script de démarrage :
```powershell
\\domain\NETLOGON\deploy-rustdesk.ps1 -ServerDomain "rustdesk.bh-systems.be" -PublicKey "votre_cle" -Environment prod
```

### Déploiement via SCCM/Intune

Créez un package avec le script et déployez-le sur les collections de machines cibles.

## 🐧 Linux

### Installation en développement

```bash
# Ubuntu/Debian/RHEL/CentOS/Fedora
sudo bash deployment/deploy-linux.sh dev
```

### Installation en production

```bash
sudo bash deployment/deploy-linux.sh prod rustdesk.bh-systems.be votre_cle_publique_ici
```

### Distributions supportées

- ✅ Ubuntu 20.04+
- ✅ Debian 11+
- ✅ RHEL 8+
- ✅ CentOS 8+
- ✅ Fedora 35+
- ✅ Rocky Linux 8+
- ✅ AlmaLinux 8+

### Architectures supportées

- ✅ x86_64 (AMD64)
- ✅ ARM64 (aarch64)

### Déploiement via Ansible

Exemple de playbook :

```yaml
---
- name: Deploy RustDesk
  hosts: all
  become: yes
  tasks:
    - name: Copy deployment script
      copy:
        src: deployment/deploy-linux.sh
        dest: /tmp/deploy-rustdesk.sh
        mode: '0755'
    
    - name: Execute deployment
      shell: /tmp/deploy-rustdesk.sh prod rustdesk.bh-systems.be votre_cle_publique
      args:
        creates: /usr/bin/rustdesk
```

## 🍎 macOS

### Installation en développement

```bash
sudo bash deployment/deploy-macos.sh dev
```

### Installation en production

```bash
sudo bash deployment/deploy-macos.sh prod rustdesk.bh-systems.be votre_cle_publique_ici
```

### Architectures supportées

- ✅ Intel (x86_64)
- ✅ Apple Silicon (ARM64/M1/M2/M3)

### Configuration des permissions

Après l'installation, l'utilisateur doit :

1. Aller dans **Préférences Système** → **Sécurité et Confidentialité**
2. Onglet **Accessibilité**
3. Cliquer sur le cadenas 🔒 pour déverrouiller
4. Cocher **RustDesk** dans la liste

### Déploiement via MDM (Jamf, Intune, etc.)

1. Créez un package .pkg à partir du script
2. Uploadez-le sur votre MDM
3. Déployez sur les machines cibles

## 🚀 Déploiement Massif

### Option 1: Script Bash centralisé (Linux/macOS)

```bash
#!/bin/bash
# deploy-all.sh

SERVER="rustdesk.bh-systems.be"
KEY="votre_cle_publique"
MACHINES="machine1 machine2 machine3"

for machine in $MACHINES; do
    echo "Déploiement sur $machine..."
    ssh root@$machine "bash -s" < deployment/deploy-linux.sh prod $SERVER $KEY
done
```

### Option 2: PowerShell Remoting (Windows)

```powershell
# deploy-all-windows.ps1

$ServerDomain = "rustdesk.bh-systems.be"
$PublicKey = "votre_cle_publique"
$Machines = @("PC001", "PC002", "PC003")

foreach ($Machine in $Machines) {
    Write-Host "Déploiement sur $Machine..."
    Invoke-Command -ComputerName $Machine -FilePath .\deployment\deploy-windows.ps1 `
        -ArgumentList $ServerDomain, $PublicKey, "prod"
}
```

### Option 3: Configuration Management

#### Ansible (Linux)
```yaml
- hosts: all
  roles:
    - rustdesk-client
```

#### Puppet (Multi-OS)
```puppet
class rustdesk {
  file { '/tmp/deploy-rustdesk.sh':
    source => 'puppet:///modules/rustdesk/deploy-linux.sh',
    mode   => '0755',
  }
  exec { 'install-rustdesk':
    command => '/tmp/deploy-rustdesk.sh prod rustdesk.bh-systems.be votre_cle',
    creates => '/usr/bin/rustdesk',
  }
}
```

## 🔍 Vérification

### Windows
```powershell
# Vérifier l'installation
Get-Service RustDesk
Get-ItemProperty -Path "HKLM:\SOFTWARE\RustDesk"

# Vérifier la configuration
Get-Content "$env:AppData\RustDesk\config\RustDesk2.toml"
```

### Linux
```bash
# Vérifier le service
systemctl status rustdesk

# Vérifier la configuration
cat /root/.config/rustdesk/RustDesk2.toml
cat /etc/rustdesk/rustdesk.toml
```

### macOS
```bash
# Vérifier l'installation
ls -la "/Applications/RustDesk.app"

# Vérifier la configuration
cat "$HOME/Library/Application Support/RustDesk/RustDesk2.toml"
```

## 🐛 Dépannage

### La connexion au serveur échoue

1. Vérifier la connectivité réseau :
```bash
# Linux/macOS
ping rustdesk.bh-systems.be
telnet rustdesk.bh-systems.be 21116

# Windows
Test-NetConnection -ComputerName rustdesk.bh-systems.be -Port 21116
```

2. Vérifier la clé publique :
```bash
# Sur le serveur
docker exec rustdesk-hbbs cat /root/id_ed25519.pub

# Sur le client
cat /root/.config/rustdesk/RustDesk2.toml
```

### Le service ne démarre pas (Linux)

```bash
# Voir les logs
journalctl -u rustdesk -n 50

# Redémarrer le service
systemctl restart rustdesk
```

### Permissions refusées (macOS)

Vérifier dans **Préférences Système** → **Sécurité et Confidentialité** → **Accessibilité**

## 📊 Monitoring

### Vérifier les connexions sur le serveur

```bash
# Voir les logs du serveur
docker logs rustdesk-hbbs-dev

# Compter les clients connectés
docker exec rustdesk-hbbs-dev sqlite3 /root/db_v2.sqlite3 "SELECT COUNT(*) FROM peer;"

# Lister les clients connectés
docker exec rustdesk-hbbs-dev sqlite3 /root/db_v2.sqlite3 "SELECT id, last_reg_time FROM peer ORDER BY last_reg_time DESC LIMIT 10;"
```

## 🔐 Sécurité

### Bonnes pratiques

1. **Changez la clé publique** en production (ne pas utiliser celle par défaut)
2. **Utilisez SSL/TLS** en production
3. **Configurez l'authentification LDAP/AD** pour les grandes organisations
4. **Limitez l'accès réseau** via firewall (ports 21115-21119 uniquement)
5. **Activez les logs d'audit** sur le serveur

### Générer une nouvelle clé

```bash
# Sur le serveur, supprimer les clés existantes
rm -f data/id_ed25519 data/id_ed25519.pub

# Redémarrer pour générer de nouvelles clés
docker-compose restart hbbs hbbr

# Récupérer la nouvelle clé publique
cat data/id_ed25519.pub
```

## 📝 Licence

Voir [LICENSE](../LICENSE)
