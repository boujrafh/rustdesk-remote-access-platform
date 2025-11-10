# Guide de Configuration des Clients RustDesk

Ce document explique comment configurer RustDesk sur vos 3 ordinateurs pour vous connecter entre eux.

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Configuration du serveur (déjà fait)](#configuration-du-serveur)
3. [Installation des clients](#installation-des-clients)
4. [Configuration des clients](#configuration-des-clients)
5. [Test de connexion](#test-de-connexion)
6. [Dépannage](#dépannage)

---

## 🎯 Vue d'ensemble

### Votre configuration actuelle

```
┌─────────────────────────────┐
│  Machine Windows (serveur)  │
│  - RustDesk Server          │
│  - IP: 127.0.0.1 (local)    │
│  - Port: 21116, 21117       │
└─────────────────────────────┘
           │
           ├─────────────────────────────┐
           │                             │
┌──────────▼──────────┐      ┌──────────▼──────────┐
│  Machine Windows    │      │  Machine Linux      │
│  (client 1)         │      │  (client 2)         │
│  + RustDesk Client  │      │  + RustDesk Client  │
└─────────────────────┘      └─────────────────────┘
```

**Important:** Pour le test local, toutes les machines doivent être sur le **même réseau local** (même WiFi/même switch).

---

## ✅ Configuration du serveur (déjà fait)

Votre serveur RustDesk tourne déjà sur votre machine Windows :

- **hbbs** : ID/Rendezvous Server (port 21116)
- **hbbr** : Relay Server (port 21117)
- **Clé publique** : `zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=`

Vérifiez que le serveur tourne :

```powershell
docker ps
```

Vous devez voir :
```
rustdesk-hbbs-dev    (port 21115-21116)
rustdesk-hbbr-dev    (port 21117)
rustdesk-nginx-dev   (port 8080)
```

---

## 📥 Installation des clients

### 1. Machine Windows (Client)

#### Télécharger RustDesk

```powershell
# Créer un dossier temporaire
New-Item -ItemType Directory -Path "C:\Temp\RustDesk" -Force

# Télécharger la dernière version
$url = "https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.exe"
Invoke-WebRequest -Uri $url -OutFile "C:\Temp\RustDesk\rustdesk-setup.exe"

# Installer (mode silencieux)
Start-Process "C:\Temp\RustDesk\rustdesk-setup.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
```

Ou téléchargez manuellement depuis : https://github.com/rustdesk/rustdesk/releases

#### Installation manuelle

1. Double-cliquez sur `rustdesk-setup.exe`
2. Suivez l'assistant d'installation
3. Laissez les options par défaut
4. Cliquez sur "Installer"

---

### 2. Machine Linux (Client)

#### Ubuntu / Debian

```bash
# Télécharger le package .deb
cd ~/Downloads
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb

# Installer
sudo apt update
sudo apt install -y ./rustdesk-1.2.3-x86_64.deb

# Ou avec dpkg
sudo dpkg -i rustdesk-1.2.3-x86_64.deb
sudo apt-get install -f  # Résoudre les dépendances manquantes
```

#### Fedora / RHEL / CentOS

```bash
# Télécharger le package .rpm
cd ~/Downloads
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.rpm

# Installer
sudo dnf install -y ./rustdesk-1.2.3-x86_64.rpm

# Ou avec yum (anciennes versions)
sudo yum install -y ./rustdesk-1.2.3-x86_64.rpm
```

#### Arch Linux

```bash
# Avec yay
yay -S rustdesk

# Ou avec paru
paru -S rustdesk
```

#### Vérifier l'installation

```bash
# Lancer RustDesk
rustdesk &

# Ou depuis le menu Applications
```

---

## ⚙️ Configuration des clients

### Étape 1: Trouver l'IP du serveur

Sur la machine qui héberge le serveur Docker (votre machine Windows de travail) :

```powershell
# Trouver votre IP locale
ipconfig

# Cherchez "IPv4 Address" dans la section de votre carte réseau active
# Exemple: 192.168.1.100
```

Ou utilisez cette commande rapide :

```powershell
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"}).IPAddress
```

**Notez cette IP**, par exemple : `192.168.1.100`

---

### Étape 2: Configurer les clients Windows

1. **Lancer RustDesk** (icône sur le bureau ou menu Démarrer)

2. **Ouvrir les paramètres**
   - Cliquez sur les **3 points** (⋮) en haut à droite
   - Sélectionnez **"Settings"** / **"Paramètres"**

3. **Aller dans Network / Réseau**
   - Cliquez sur l'onglet **"Network"** / **"Réseau"**

4. **Configurer le serveur personnalisé**
   
   Dans la section **"ID/Relay Server"** :
   
   ```
   ID Server:          192.168.1.100        (remplacez par votre IP)
   Relay Server:       192.168.1.100        (la même IP)
   API Server:         (laissez vide pour le test)
   Key:                zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=
   ```

5. **Appliquer les paramètres**
   - Cliquez sur **"Apply"** / **"Appliquer"**
   - Attendez que le statut devienne **"Ready"** / **"Prêt"** (point vert)

---

### Étape 3: Configurer le client Linux

1. **Lancer RustDesk**
   ```bash
   rustdesk &
   ```

2. **Ouvrir les paramètres**
   - Cliquez sur les **3 points** (⋮) en haut à droite
   - Sélectionnez **"Settings"**

3. **Aller dans Network**
   - Cliquez sur l'onglet **"Network"**

4. **Configurer le serveur personnalisé**
   
   Dans la section **"ID/Relay Server"** :
   
   ```
   ID Server:          192.168.1.100
   Relay Server:       192.168.1.100
   API Server:         (laissez vide)
   Key:                zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=
   ```

5. **Appliquer**
   - Cliquez sur **"Apply"**
   - Vérifiez le statut : **point vert** = connecté

**Alternative : Configuration en ligne de commande (Linux)**

```bash
# Créer le fichier de configuration
mkdir -p ~/.config/rustdesk

# Éditer le fichier
nano ~/.config/rustdesk/RustDesk.toml

# Ajouter cette configuration (remplacez 192.168.1.100 par votre IP)
```

Contenu du fichier `RustDesk.toml` :

```toml
[options]
relay-server = "192.168.1.100"
id-server = "192.168.1.100"
key = "zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE="
```

Sauvegarder avec `Ctrl+X`, `Y`, `Enter`.

Redémarrer RustDesk :

```bash
killall rustdesk
rustdesk &
```

---

## 🔗 Test de connexion

### Récupérer les ID des machines

Sur **chaque machine** (Windows et Linux), notez l'**ID RustDesk** :

1. Ouvrez RustDesk
2. L'ID est affiché en haut de la fenêtre principale
3. Exemple : `123 456 789`

**Notez les ID :**

```
Machine 1 (Windows Serveur):   ___ ___ ___
Machine 2 (Windows Client):    ___ ___ ___
Machine 3 (Linux Client):      ___ ___ ___
```

---

### Se connecter d'une machine à l'autre

#### Depuis n'importe quelle machine → vers une autre

1. **Lancer RustDesk** sur la machine source

2. **Entrer l'ID de destination**
   - Dans le champ "Remote ID" / "ID distant"
   - Tapez l'ID de la machine cible (exemple: `123456789`)

3. **Cliquer sur "Connect"** / **"Connexion"**

4. **Entrer le mot de passe**
   - Chaque machine a un mot de passe visible dans sa fenêtre RustDesk
   - Sous l'ID, vous verrez : `Password: xxxxxx`
   - Entrez ce mot de passe

5. **Connexion établie !**
   - Vous devez voir l'écran de la machine distante
   - Vous pouvez contrôler la souris et le clavier

---

## 🎨 Options de connexion

### Qualité de la connexion

- **View Only** : Voir seulement, pas de contrôle
- **File Transfer** : Transférer des fichiers uniquement
- **Remote Desktop** : Contrôle total (par défaut)

### Modifier le mot de passe permanent

Par défaut, RustDesk génère un mot de passe aléatoire. Pour le changer :

1. Ouvrez **Settings** / **Paramètres**
2. Allez dans **Security** / **Sécurité**
3. Section **"Password"** / **"Mot de passe"**
4. Cochez **"Use permanent password"** / **"Utiliser un mot de passe permanent"**
5. Entrez votre mot de passe personnalisé
6. Cliquez sur **"Apply"** / **"Appliquer"**

**Recommandation :** Utilisez un mot de passe fort (12+ caractères, majuscules, minuscules, chiffres, symboles).

---

## 🔧 Dépannage

### Problème 1 : "Not ready" / "Pas prêt" (point rouge)

**Causes possibles :**
- Serveur RustDesk non démarré
- Mauvaise IP configurée
- Firewall bloque les ports

**Solutions :**

1. **Vérifier que le serveur tourne**
   ```powershell
   docker ps
   ```

2. **Vérifier l'IP configurée**
   - L'IP doit être celle de la machine serveur sur le réseau local
   - Pas `127.0.0.1` (sauf pour le serveur lui-même)

3. **Tester la connectivité réseau**
   
   Depuis les machines clientes :
   
   ```powershell
   # Windows
   Test-NetConnection -ComputerName 192.168.1.100 -Port 21116
   ```
   
   ```bash
   # Linux
   telnet 192.168.1.100 21116
   # ou
   nc -zv 192.168.1.100 21116
   ```
   
   Vous devez voir "Connected" / "Connexion réussie"

4. **Vérifier le firewall Windows**
   
   Sur la machine serveur :
   
   ```powershell
   # Autoriser les ports RustDesk
   New-NetFirewallRule -DisplayName "RustDesk ID Server" -Direction Inbound -Protocol TCP -LocalPort 21115,21116 -Action Allow
   New-NetFirewallRule -DisplayName "RustDesk ID Server UDP" -Direction Inbound -Protocol UDP -LocalPort 21116 -Action Allow
   New-NetFirewallRule -DisplayName "RustDesk Relay" -Direction Inbound -Protocol TCP -LocalPort 21117 -Action Allow
   ```

---

### Problème 2 : "Connection timeout" / "Délai de connexion dépassé"

**Solutions :**

1. **Vérifier que l'ID est correct**
   - Pas d'espaces supplémentaires
   - Chiffres corrects

2. **Vérifier que la machine cible est allumée et RustDesk est lancé**

3. **Désactiver temporairement le firewall pour tester**
   
   Windows (machine cible) :
   ```powershell
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   ```
   
   Linux (machine cible) :
   ```bash
   sudo ufw disable
   # ou
   sudo systemctl stop firewalld
   ```
   
   **⚠️ N'oubliez pas de réactiver après le test !**

---

### Problème 3 : "Invalid password" / "Mot de passe invalide"

**Solutions :**

1. **Vérifier le mot de passe affiché sur la machine cible**
   - Le mot de passe change si RustDesk redémarre (sauf si permanent)

2. **Copier-coller le mot de passe** au lieu de le taper

3. **Configurer un mot de passe permanent** (voir section précédente)

---

### Problème 4 : Connexion lente ou saccadée

**Solutions :**

1. **Vérifier la qualité réseau**
   ```powershell
   # Windows
   ping 192.168.1.100
   ```
   
   ```bash
   # Linux
   ping -c 10 192.168.1.100
   ```

2. **Réduire la qualité d'image**
   - Pendant la connexion : Menu → Quality → Low

3. **Utiliser la connexion directe P2P** (sans relay)
   - RustDesk essaie automatiquement
   - Si ça passe par le relay, vérifiez le NAT/firewall

4. **Augmenter les ressources du serveur**
   
   Éditez `.env.dev` :
   ```bash
   # Augmenter les limites
   HBBS_CPU_LIMIT=2
   HBBS_MEMORY_LIMIT=2048M
   HBBR_CPU_LIMIT=4
   HBBR_MEMORY_LIMIT=4096M
   ```
   
   Redémarrez :
   ```powershell
   docker-compose -f docker-compose.dev.yml --env-file .env.dev down
   docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d
   ```

---

### Problème 5 : Linux - Erreur "Wayland not supported"

**Solution :** Utiliser X11 au lieu de Wayland

1. **Se déconnecter de la session**

2. **À l'écran de connexion :**
   - Cliquez sur l'icône d'engrenage (⚙️)
   - Sélectionnez **"Ubuntu on Xorg"** / **"GNOME on Xorg"**
   - Connectez-vous

3. **Ou forcer X11 en ligne de commande**
   ```bash
   # Éditer le fichier GDM
   sudo nano /etc/gdm3/custom.conf
   
   # Décommenter cette ligne
   WaylandEnable=false
   
   # Redémarrer
   sudo systemctl restart gdm3
   ```

---

## 📊 Vérification de l'état

### Vérifier les logs du serveur

```powershell
# Logs du serveur ID/Rendezvous
docker logs rustdesk-hbbs-dev

# Logs du relay
docker logs rustdesk-hbbr-dev

# Suivre les logs en temps réel
docker logs -f rustdesk-hbbs-dev
```

Ce que vous devez voir quand un client se connecte :

```
[INFO] New peer registered: 123456789
[INFO] Peer 123456789 online
```

---

### Vérifier les connexions actives

```powershell
# Vérifier les ports écoutés
netstat -an | Select-String "21115|21116|21117"
```

Vous devez voir :
```
TCP    0.0.0.0:21115    LISTENING
TCP    0.0.0.0:21116    LISTENING
TCP    0.0.0.0:21117    LISTENING
UDP    0.0.0.0:21116    *:*
```

---

## 📱 Exemple complet de connexion

### Scénario : Se connecter depuis Linux vers Windows

1. **Sur Windows (machine cible)**
   - Lancer RustDesk
   - Noter l'ID : `987 654 321`
   - Noter le mot de passe : `abcdef`
   - Statut : **Prêt** (point vert)

2. **Sur Linux (machine source)**
   - Lancer RustDesk
   ```bash
   rustdesk &
   ```
   - Vérifier le statut : **Prêt** (point vert)
   - Entrer l'ID distant : `987654321`
   - Cliquer sur **"Connect"**

3. **Dialogue de connexion**
   - Entrer le mot de passe : `abcdef`
   - Cliquer sur **"OK"**

4. **Connexion établie !**
   - L'écran Windows s'affiche sur Linux
   - Vous pouvez contrôler Windows depuis Linux

---

## 🔐 Sécurité pour les tests locaux

Pour les tests en environnement local, les paramètres par défaut sont OK. Mais voici quelques bonnes pratiques :

### 1. Mot de passe permanent fort

```
Minimum 12 caractères
Exemple: RustDesk2024!Test#123
```

### 2. Ne pas exposer sur Internet

- Gardez les ports 21115-21119 **fermés** sur votre routeur
- Utilisez uniquement en réseau local pour les tests

### 3. Limiter l'accès

Dans RustDesk Settings → Security :
- Cochez **"Require click to show password"**
- Cochez **"Disable clipboard"** si nécessaire
- Cochez **"Disable file transfer"** si non utilisé

---

## ✅ Checklist de configuration

### Machine Serveur (Windows avec Docker)

- [ ] Docker Desktop installé et démarré
- [ ] `docker-compose.dev.yml` déployé
- [ ] Containers `hbbs-dev` et `hbbr-dev` en cours d'exécution
- [ ] IP locale notée (ex: `192.168.1.100`)
- [ ] Clé publique notée : `zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=`
- [ ] Firewall configuré pour autoriser les ports 21115-21117
- [ ] RustDesk client installé (optionnel, pour tester aussi depuis cette machine)

### Machine Cliente Windows

- [ ] RustDesk client installé
- [ ] Settings → Network → ID Server configuré avec l'IP du serveur
- [ ] Settings → Network → Relay Server configuré avec l'IP du serveur
- [ ] Settings → Network → Key configurée
- [ ] Statut : **Prêt** (point vert)
- [ ] ID RustDesk noté

### Machine Cliente Linux

- [ ] RustDesk client installé (`.deb` ou `.rpm`)
- [ ] Settings → Network → ID Server configuré avec l'IP du serveur
- [ ] Settings → Network → Relay Server configuré avec l'IP du serveur
- [ ] Settings → Network → Key configurée
- [ ] Statut : **Prêt** (point vert)
- [ ] X11 activé (si Wayland posait problème)
- [ ] ID RustDesk noté

---

## 🎯 Résumé rapide

### Configuration minimale

1. **Installer RustDesk sur toutes les machines**
2. **Trouver l'IP du serveur** : `ipconfig` sur Windows
3. **Configurer chaque client** :
   - ID Server: `192.168.1.100` (votre IP)
   - Relay Server: `192.168.1.100`
   - Key: `zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE=`
4. **Noter les ID de chaque machine**
5. **Se connecter** : Entrer l'ID distant + mot de passe

C'est tout ! 🎉

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Consultez la section [Dépannage](#dépannage)
2. Vérifiez les logs du serveur : `docker logs rustdesk-hbbs-dev`
3. Vérifiez la connectivité réseau : `ping` et `telnet`
4. Consultez la documentation officielle : https://rustdesk.com/docs/

---

## 📚 Liens utiles

- [Site officiel RustDesk](https://rustdesk.com/)
- [GitHub RustDesk](https://github.com/rustdesk/rustdesk)
- [Documentation serveur](https://rustdesk.com/docs/en/self-host/)
- [Forum communautaire](https://github.com/rustdesk/rustdesk/discussions)

---

**Bon test ! 🚀**
