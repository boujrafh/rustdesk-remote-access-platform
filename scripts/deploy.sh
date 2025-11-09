#!/bin/bash
# RustDesk Platform Deployment Script
# Run this script to deploy RustDesk with all necessary configurations

set -e

echo "======================================"
echo "RustDesk Platform Deployment Script"
echo "======================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run this script as root${NC}"
    exit 1
fi

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_info "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_info "Prerequisites check passed!"

# Check if .env exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from template..."
    cp .env.example .env
    
    # Generate random secrets
    API_SECRET=$(openssl rand -base64 32)
    SESSION_SECRET=$(openssl rand -base64 32)
    DB_PASSWORD=$(openssl rand -base64 24)
    
    # Update .env with generated secrets
    sed -i "s/CHANGE_ME_STRONG_PASSWORD/$DB_PASSWORD/g" .env
    sed -i "s/CHANGE_ME_RANDOM_SECRET_KEY/$API_SECRET/g" .env
    sed -i "s/CHANGE_ME_SESSION_SECRET/$SESSION_SECRET/g" .env
    
    print_warning "Please edit .env file with your configuration before continuing."
    print_warning "Required: SERVER_DOMAIN, PUBLIC_IP"
    read -p "Press Enter after editing .env file to continue..."
fi

# Create necessary directories
print_info "Creating directory structure..."
mkdir -p data
mkdir -p postgres-data
mkdir -p api-data
mkdir -p nginx/logs
mkdir -p nginx/html
mkdir -p certs
mkdir -p backups

# Check SSL certificates
print_info "Checking SSL certificates..."
if [ ! -f certs/fullchain.pem ] || [ ! -f certs/privkey.pem ]; then
    print_warning "SSL certificates not found."
    echo "Options:"
    echo "1) Let's Encrypt (Production)"
    echo "2) Self-signed (Testing only)"
    read -p "Choose option (1 or 2): " SSL_CHOICE
    
    if [ "$SSL_CHOICE" == "1" ]; then
        read -p "Enter your domain name: " DOMAIN
        print_info "Obtaining Let's Encrypt certificate for $DOMAIN..."
        sudo certbot certonly --standalone -d $DOMAIN --agree-tos --register-unsafely-without-email --non-interactive
        sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem certs/
        sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem certs/
        sudo chmod 644 certs/*.pem
        sudo chown $USER:$USER certs/*.pem
        print_info "Certificate obtained successfully!"
    else
        print_info "Generating self-signed certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout certs/privkey.pem \
            -out certs/fullchain.pem \
            -subj "/CN=rustdesk.local"
        print_warning "Self-signed certificate created. For testing only!"
    fi
fi

# Create welcome page
print_info "Creating web console landing page..."
cat > nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RustDesk Remote Access Platform</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .container { text-align: center; max-width: 600px; padding: 40px; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border-radius: 20px; box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37); }
        h1 { margin-bottom: 20px; font-size: 2.5em; }
        p { font-size: 1.2em; line-height: 1.6; }
        .status { margin-top: 30px; padding: 15px; background: rgba(255,255,255,0.2); border-radius: 10px; }
        .status.online { background: rgba(76, 175, 80, 0.3); }
        a { color: #ffeb3b; text-decoration: none; font-weight: bold; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖥️ RustDesk Platform</h1>
        <p>Welcome to your self-hosted RustDesk Remote Access Server</p>
        <div class="status online">
            <strong>✓ Server Status: Online</strong>
        </div>
        <p style="margin-top: 30px; font-size: 0.9em;">
            Download RustDesk client: <a href="https://rustdesk.com/" target="_blank">rustdesk.com</a><br>
            <br>
            For support, contact your IT administrator.
        </p>
    </div>
</body>
</html>
EOF

# Configure firewall
print_info "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 21115:21119/tcp
    sudo ufw allow 21116/udp
    print_info "UFW rules added"
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=21115-21119/tcp
    sudo firewall-cmd --permanent --add-port=21116/udp
    sudo firewall-cmd --reload
    print_info "Firewalld rules added"
else
    print_warning "No supported firewall found. Please configure manually."
fi

# Pull Docker images
print_info "Pulling Docker images..."
docker-compose pull

# Start services
print_info "Starting RustDesk services..."
read -p "Deploy with API server? (y/n): " DEPLOY_API

if [ "$DEPLOY_API" == "y" ]; then
    docker-compose --profile full up -d
else
    docker-compose up -d
fi

# Wait for services to start
print_info "Waiting for services to start..."
sleep 10

# Check service status
print_info "Checking service status..."
docker-compose ps

echo ""
echo "======================================"
print_info "Deployment completed successfully!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Verify all containers are running: docker-compose ps"
echo "2. Check logs: docker-compose logs -f"
echo "3. Access web console: https://$(grep SERVER_DOMAIN .env | cut -d '=' -f2)"
echo "4. Configure RustDesk clients with server address"
echo ""
echo "For detailed instructions, see docs/ADMIN_GUIDE.md"
echo ""
