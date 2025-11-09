#!/bin/bash
#
# Script de déploiement automatique de RustDesk pour Linux
# Supporte: Ubuntu, Debian, RHEL, CentOS, Fedora
#
# Usage:
#   sudo ./deploy-linux.sh dev
#   sudo ./deploy-linux.sh prod rustdesk.bh-systems.be votre_cle_publique
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

# Détecter la distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}Impossible de détecter la distribution${NC}"
        exit 1
    fi
}

echo -e "${CYAN}=== Déploiement RustDesk pour Linux ===${NC}"
echo ""

# Étape 1: Détecter la distribution
echo -e "${YELLOW}[1/6] Détection de la distribution...${NC}"
detect_distro
echo -e "${GREEN}Distribution détectée: $OS $VER${NC}"

# Étape 2: Installer les dépendances
echo -e "${YELLOW}[2/6] Installation des dépendances...${NC}"
case $OS in
    ubuntu|debian)
        apt-get update -qq
        apt-get install -y wget curl
        ;;
    rhel|centos|fedora|rocky|alma)
        yum install -y wget curl || dnf install -y wget curl
        ;;
    *)
        echo -e "${RED}Distribution non supportée: $OS${NC}"
        exit 1
        ;;
esac
echo -e "${GREEN}Dépendances installées.${NC}"

# Étape 3: Télécharger RustDesk
echo -e "${YELLOW}[3/6] Téléchargement de RustDesk...${NC}"

# Détecter l'architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-x86_64.deb"
        PACKAGE_FILE="/tmp/rustdesk.deb"
        ;;
    aarch64|arm64)
        RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-aarch64.deb"
        PACKAGE_FILE="/tmp/rustdesk.deb"
        ;;
    *)
        echo -e "${RED}Architecture non supportée: $ARCH${NC}"
        exit 1
        ;;
esac

# Pour RHEL/CentOS, utiliser le package RPM
if [[ "$OS" =~ ^(rhel|centos|fedora|rocky|alma)$ ]]; then
    if [ "$ARCH" = "x86_64" ]; then
        RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-x86_64.rpm"
        PACKAGE_FILE="/tmp/rustdesk.rpm"
    else
        RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.3.6-aarch64.rpm"
        PACKAGE_FILE="/tmp/rustdesk.rpm"
    fi
fi

wget -q --show-progress "$RUSTDESK_URL" -O "$PACKAGE_FILE"
echo -e "${GREEN}Téléchargement terminé.${NC}"

# Étape 4: Installer RustDesk
echo -e "${YELLOW}[4/6] Installation de RustDesk...${NC}"

# Arrêter RustDesk s'il est en cours d'exécution
systemctl stop rustdesk 2>/dev/null || true
killall rustdesk 2>/dev/null || true

case $OS in
    ubuntu|debian)
        dpkg -i "$PACKAGE_FILE" || apt-get install -f -y
        ;;
    rhel|centos|fedora|rocky|alma)
        if command -v dnf &> /dev/null; then
            dnf install -y "$PACKAGE_FILE"
        else
            yum install -y "$PACKAGE_FILE"
        fi
        ;;
esac

echo -e "${GREEN}Installation terminée.${NC}"

# Étape 5: Configuration du serveur personnalisé
echo -e "${YELLOW}[5/6] Configuration du serveur personnalisé...${NC}"

# Créer le dossier de configuration
CONFIG_DIR="/root/.config/rustdesk"
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

echo -e "${GREEN}Configuration enregistrée dans: $CONFIG_DIR/RustDesk2.toml${NC}"

# Configuration pour tous les utilisateurs
GLOBAL_CONFIG="/etc/rustdesk/rustdesk.toml"
mkdir -p /etc/rustdesk

cat > "$GLOBAL_CONFIG" << EOF
# RustDesk Global Configuration
id_server = "$SERVER_DOMAIN"
relay_server = "$SERVER_DOMAIN"
key = "$PUBLIC_KEY"
EOF

echo -e "${GREEN}Configuration globale enregistrée dans: $GLOBAL_CONFIG${NC}"

# Étape 6: Activer et démarrer le service
echo -e "${YELLOW}[6/6] Activation du service RustDesk...${NC}"

# Activer le service au démarrage
systemctl enable rustdesk 2>/dev/null || true
systemctl start rustdesk 2>/dev/null || true

echo ""
echo -e "${GREEN}=== Installation terminée avec succès ! ===${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "  - Serveur ID: ${GREEN}$SERVER_DOMAIN${NC}"
echo -e "  - Serveur Relay: ${GREEN}$SERVER_DOMAIN${NC}"
echo -e "  - Clé publique: ${GREEN}$PUBLIC_KEY${NC}"
echo ""
echo -e "${GREEN}RustDesk est maintenant installé et configuré.${NC}"
echo -e "${YELLOW}Pour obtenir l'ID de cette machine, exécutez: rustdesk${NC}"
echo ""

# Nettoyage
rm -f "$PACKAGE_FILE"

# Afficher le statut du service
echo -e "${CYAN}Statut du service:${NC}"
systemctl status rustdesk --no-pager || true
