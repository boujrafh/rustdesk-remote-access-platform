#!/bin/bash
#
# Script de configuration firewall pour environnement SFN sécurisé
# Autorise UNIQUEMENT les ports RustDesk nécessaires
# Usage: sudo ./firewall-sfn.sh enable|disable|status
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Vérifier les privilèges root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ce script doit être exécuté en tant que root (utilisez sudo)${NC}"
    exit 1
fi

ACTION=${1:-status}

enable_firewall() {
    echo -e "${YELLOW}Configuration du firewall SFN...${NC}"
    
    # Sauvegarder les règles actuelles
    iptables-save > /etc/iptables/rules.backup.$(date +%Y%m%d_%H%M%S)
    
    # Flush existing rules
    echo "Nettoyage des règles existantes..."
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Default policy: DROP (tout bloquer par défaut)
    echo "Application de la politique par défaut: DROP"
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    echo "Autorisation interface loopback..."
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    echo "Autorisation connexions établies..."
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # RustDesk ports UNIQUEMENT
    echo "Configuration ports RustDesk..."
    
    # hbbs - NAT type test
    iptables -A INPUT -p tcp --dport 21115 -m comment --comment "RustDesk hbbs NAT test" -j ACCEPT
    
    # hbbs - ID registration & heartbeat
    iptables -A INPUT -p tcp --dport 21116 -m comment --comment "RustDesk hbbs registration TCP" -j ACCEPT
    iptables -A INPUT -p udp --dport 21116 -m comment --comment "RustDesk hbbs registration UDP" -j ACCEPT
    
    # hbbr - Relay
    iptables -A INPUT -p tcp --dport 21117 -m comment --comment "RustDesk hbbr relay" -j ACCEPT
    
    # hbbs - WebSocket
    iptables -A INPUT -p tcp --dport 21118 -m comment --comment "RustDesk hbbs WebSocket" -j ACCEPT
    
    # hbbr - WebSocket relay
    iptables -A INPUT -p tcp --dport 21119 -m comment --comment "RustDesk hbbr WebSocket" -j ACCEPT
    
    # HTTPS pour API (optionnel, commentez si non utilisé)
    iptables -A INPUT -p tcp --dport 443 -m comment --comment "RustDesk API HTTPS" -j ACCEPT
    
    # SSH - UNIQUEMENT depuis le réseau d'administration
    # Adaptez le réseau source selon votre configuration
    echo "Configuration SSH (réseau admin uniquement)..."
    iptables -A INPUT -p tcp -s 10.0.0.0/8 --dport 22 -m comment --comment "SSH admin network" -j ACCEPT
    
    # ICMP (ping) - optionnel
    iptables -A INPUT -p icmp --icmp-type echo-request -m comment --comment "ICMP ping" -j ACCEPT
    
    # Log dropped packets (pour audit)
    echo "Configuration des logs..."
    iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "SFN-FIREWALL-DROP: " --log-level 4
    
    # Sauvegarder les règles
    echo "Sauvegarde des règles..."
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    else
        iptables-save > /etc/iptables/rules.v4
    fi
    
    echo -e "${GREEN}✅ Firewall SFN activé avec succès${NC}"
    echo ""
    echo -e "${YELLOW}Ports autorisés:${NC}"
    echo "  - 21115 (TCP) : hbbs NAT test"
    echo "  - 21116 (TCP/UDP) : hbbs registration"
    echo "  - 21117 (TCP) : hbbr relay"
    echo "  - 21118 (TCP) : hbbs WebSocket"
    echo "  - 21119 (TCP) : hbbr WebSocket"
    echo "  - 443 (TCP) : API HTTPS"
    echo "  - 22 (TCP) : SSH (réseau admin uniquement)"
}

disable_firewall() {
    echo -e "${YELLOW}Désactivation du firewall SFN...${NC}"
    
    # Sauvegarder avant de désactiver
    iptables-save > /etc/iptables/rules.before-disable.$(date +%Y%m%d_%H%M%S)
    
    # Flush all rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Set default policy to ACCEPT
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    echo -e "${GREEN}✅ Firewall SFN désactivé${NC}"
    echo -e "${RED}⚠️  ATTENTION: Tous les ports sont maintenant ouverts !${NC}"
}

show_status() {
    echo -e "${YELLOW}=== Statut du Firewall SFN ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Politique par défaut:${NC}"
    iptables -L -n | grep "policy"
    echo ""
    
    echo -e "${YELLOW}Règles INPUT:${NC}"
    iptables -L INPUT -n -v --line-numbers
    echo ""
    
    echo -e "${YELLOW}Ports en écoute:${NC}"
    netstat -tuln | grep -E "21115|21116|21117|21118|21119|443|22"
    echo ""
    
    echo -e "${YELLOW}Connexions actives RustDesk:${NC}"
    netstat -tn | grep -E "21115|21116|21117|21118|21119" | wc -l
}

test_firewall() {
    echo -e "${YELLOW}=== Test du Firewall SFN ===${NC}"
    echo ""
    
    local test_passed=0
    local test_failed=0
    
    # Test des ports RustDesk
    for port in 21115 21116 21117 21118 21119; do
        if nc -z -w5 localhost $port 2>/dev/null; then
            echo -e "✅ Port $port : ${GREEN}ACCESSIBLE${NC}"
            ((test_passed++))
        else
            echo -e "❌ Port $port : ${RED}BLOQUÉ ou service non démarré${NC}"
            ((test_failed++))
        fi
    done
    
    echo ""
    echo "Tests réussis: $test_passed"
    echo "Tests échoués: $test_failed"
}

case $ACTION in
    enable)
        enable_firewall
        ;;
    disable)
        disable_firewall
        ;;
    status)
        show_status
        ;;
    test)
        test_firewall
        ;;
    *)
        echo "Usage: $0 {enable|disable|status|test}"
        echo ""
        echo "  enable  - Activer le firewall SFN (strict)"
        echo "  disable - Désactiver le firewall"
        echo "  status  - Afficher le statut actuel"
        echo "  test    - Tester les ports RustDesk"
        exit 1
        ;;
esac
