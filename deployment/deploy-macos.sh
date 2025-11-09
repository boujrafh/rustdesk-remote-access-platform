#!/bin/bash
#
# Script de déploiement automatique de RustDesk pour macOS
# Compatible avec macOS 10.15+ (Catalina et supérieur)
#
# Usage:
#   sudo ./deploy-macos.sh dev
#   sudo ./deploy-macos.sh prod rustdesk.bh-systems.be votre_cle_publique
#

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Vérifier les privilèges root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ce script doit être exécuté en tant que root (utilisez sudo)${NC}"
    exit 1
fi

# Vérifier que nous sommes bien sur macOS
if [ "$(uname)" != "Darwin" ]; then
    echo -e "${RED}Ce script est conçu pour macOS uniquement${NC}"
    exit 1
fi

# Paramètres
ENVIRONMENT=$1
SERVER_DOMAIN=$2
PUBLIC_KEY=$3

# Configuration selon l'environnement
if [ "$ENVIRONMENT" = "dev" ]; then
    SERVER_DOMAIN="localhost"
    PUBLIC_KEY="zTvrPCjiYLzWb1slrsULfjhtx59jiA0jum6k21IZHuE="
    echo -e "${YELLOW}Mode DÉVELOPPEMENT - Serveur: $SERVER_DOMAIN${NC}"
elif [ "$ENVIRONMENT" = "prod" ]; then
    if [ -z "$SERVER_DOMAIN" ] || [ -z "$PUBLIC_KEY" ]; then
        echo -e "${RED}ERREUR: Usage pour production: sudo $0 prod <domaine_serveur> <cle_publique>${NC}"
        exit 1
    fi
    echo -e "${GREEN}Mode PRODUCTION - Serveur: $SERVER_DOMAIN${NC}"
else
    echo -e "${RED}ERREUR: Environnement invalide. Utilisez 'dev' ou 'prod'${NC}"
    echo "Usage:"
    echo "  sudo $0 dev"
    echo "  sudo $0 prod rustdesk.bh-systems.be votre_cle_publique"
    exit 1
fi

echo -e "${CYAN}=== Déploiement RustDesk pour macOS ===${NC}"
echo ""

# Étape 1: Détecter l'architecture
echo -e "${YELLOW}[1/6] Détection de l'architecture...${NC}"
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-x86_64.dmg"
        echo -e "${GREEN}Architecture détectée: Intel (x86_64)${NC}"
        ;;
    arm64)
        RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-aarch64.dmg"
        echo -e "${GREEN}Architecture détectée: Apple Silicon (ARM64)${NC}"
        ;;
    *)
        echo -e "${RED}Architecture non supportée: $ARCH${NC}"
        exit 1
        ;;
esac

# Étape 2: Vérifier/Installer Homebrew (optionnel, pour wget)
echo -e "${YELLOW}[2/6] Vérification des outils...${NC}"
if ! command -v wget &> /dev/null; then
    echo -e "${YELLOW}wget non trouvé, utilisation de curl à la place...${NC}"
    USE_CURL=1
else
    USE_CURL=0
fi

# Étape 3: Télécharger RustDesk
echo -e "${YELLOW}[3/6] Téléchargement de RustDesk...${NC}"
DMG_FILE="/tmp/rustdesk.dmg"

if [ $USE_CURL -eq 1 ]; then
    curl -L "$RUSTDESK_URL" -o "$DMG_FILE"
else
    wget -q --show-progress "$RUSTDESK_URL" -O "$DMG_FILE"
fi

echo -e "${GREEN}Téléchargement terminé.${NC}"

# Étape 4: Installer RustDesk
echo -e "${YELLOW}[4/6] Installation de RustDesk...${NC}"

# Fermer RustDesk s'il est en cours d'exécution
echo -e "${YELLOW}Arrêt de RustDesk si en cours d'exécution...${NC}"
killall RustDesk 2>/dev/null || true
sleep 2

# Démonter tout volume RustDesk précédent
hdiutil detach "/Volumes/RustDesk" 2>/dev/null || true

# Monter le DMG
echo -e "${YELLOW}Montage du DMG...${NC}"
MOUNT_OUTPUT=$(hdiutil attach "$DMG_FILE" -nobrowse -quiet)
VOLUME=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/.*' | head -1)

if [ -z "$VOLUME" ]; then
    # Fallback si la détection échoue
    VOLUME="/Volumes/RustDesk"
fi

echo -e "${GREEN}DMG monté: $VOLUME${NC}"

# Copier l'application
echo -e "${YELLOW}Installation de RustDesk.app...${NC}"
if [ -d "/Applications/RustDesk.app" ]; then
    echo -e "${YELLOW}Suppression de l'installation précédente...${NC}"
    rm -rf "/Applications/RustDesk.app"
fi

cp -R "$VOLUME/RustDesk.app" "/Applications/"
echo -e "${GREEN}RustDesk installé dans /Applications/${NC}"

# Démonter le DMG
hdiutil detach "$VOLUME" -quiet

# Étape 5: Configuration du serveur personnalisé
echo -e "${YELLOW}[5/6] Configuration du serveur personnalisé...${NC}"

# Créer le dossier de configuration pour l'utilisateur actuel (celui qui a lancé sudo)
ACTUAL_USER=$(logname)
USER_HOME=$(eval echo ~$ACTUAL_USER)
CONFIG_DIR="$USER_HOME/Library/Application Support/RustDesk"

mkdir -p "$CONFIG_DIR"

# Créer le fichier de configuration
cat > "$CONFIG_DIR/RustDesk2.toml" << EOF
# RustDesk Configuration
# Généré automatiquement par le script de déploiement

# Serveur ID/Rendezvous
id_server = "$SERVER_DOMAIN"
relay_server = "$SERVER_DOMAIN"

# Clé publique du serveur
key = "$PUBLIC_KEY"

# API Server (optionnel)
api_server = "http://$SERVER_DOMAIN/api"

# Options de connexion
auto_connect = false
EOF

# Donner les bons permissions
chown -R "$ACTUAL_USER" "$CONFIG_DIR"

echo -e "${GREEN}Configuration enregistrée dans: $CONFIG_DIR/RustDesk2.toml${NC}"

# Configuration globale (pour tous les utilisateurs)
GLOBAL_CONFIG="/Library/Application Support/RustDesk/rustdesk.toml"
mkdir -p "/Library/Application Support/RustDesk"

cat > "$GLOBAL_CONFIG" << EOF
# RustDesk Global Configuration
id_server = "$SERVER_DOMAIN"
relay_server = "$SERVER_DOMAIN"
key = "$PUBLIC_KEY"
EOF

echo -e "${GREEN}Configuration globale enregistrée dans: $GLOBAL_CONFIG${NC}"

# Étape 6: Configuration des permissions macOS
echo -e "${YELLOW}[6/6] Configuration des permissions...${NC}"

# Ajouter RustDesk aux applications autorisées pour l'accessibilité
echo -e "${YELLOW}IMPORTANT: Vous devrez autoriser RustDesk dans les Préférences Système${NC}"
echo -e "${YELLOW}Allez dans: Préférences Système > Sécurité et Confidentialité > Accessibilité${NC}"
echo -e "${YELLOW}Et cochez RustDesk dans la liste${NC}"

# Ouvrir RustDesk
echo -e "${YELLOW}Lancement de RustDesk...${NC}"
sudo -u "$ACTUAL_USER" open -a RustDesk

echo ""
echo -e "${GREEN}=== Installation terminée avec succès ! ===${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "  - Serveur ID: ${GREEN}$SERVER_DOMAIN${NC}"
echo -e "  - Serveur Relay: ${GREEN}$SERVER_DOMAIN${NC}"
echo -e "  - Clé publique: ${GREEN}$PUBLIC_KEY${NC}"
echo ""
echo -e "${GREEN}RustDesk est maintenant installé et configuré.${NC}"
echo -e "${YELLOW}N'oubliez pas d'autoriser l'accessibilité dans les Préférences Système !${NC}"
echo ""

# Nettoyage
rm -f "$DMG_FILE"

echo -e "${CYAN}RustDesk a été lancé. L'ID de cette machine sera affiché dans la fenêtre principale.${NC}"
