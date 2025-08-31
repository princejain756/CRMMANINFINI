#!/bin/bash

# 🛠️ Server Setup Script for Maninfini Automation CRM
# Run this script on your server before deploying the CRM

set -e

echo "🛠️ Setting up server environment for Maninfini Automation CRM..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    print_error "Cannot detect OS"
    exit 1
fi

print_status "Detected OS: $OS $VER"

# Update system
print_status "Updating system packages..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    apt update && apt upgrade -y
    apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
    yum update -y
    yum install -y curl wget git unzip
else
    print_warning "Unsupported OS. Please install dependencies manually."
fi

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        usermod -aG docker $SUDO_USER
        rm get-docker.sh
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl start docker
        systemctl enable docker
        usermod -aG docker $SUDO_USER
    fi
else
    print_success "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
else
    print_success "Docker Compose is already installed"
fi

# Install Nginx (optional)
print_status "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt install -y nginx
        systemctl enable nginx
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y nginx
        systemctl enable nginx
    fi
else
    print_success "Nginx is already installed"
fi

# Install Certbot for SSL (optional)
print_status "Installing Certbot for SSL certificates..."
if ! command -v certbot &> /dev/null; then
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt install -y certbot python3-certbot-nginx
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y certbot python3-certbot-nginx
    fi
else
    print_success "Certbot is already installed"
fi

# Configure firewall
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    ufw --force enable
    print_success "UFW firewall configured"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    print_success "Firewalld configured"
else
    print_warning "No firewall detected. Please configure manually."
fi

# Create deployment directory
print_status "Creating deployment directory..."
mkdir -p /var/www/CRMMANINFINI
chown $SUDO_USER:$SUDO_USER /var/www/CRMMANINFINI

# Set up swap file if needed
print_status "Checking memory and setting up swap if needed..."
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
if [ $TOTAL_MEM -lt 4096 ]; then
    print_warning "Low memory detected (${TOTAL_MEM}MB). Setting up swap file..."
    if [ ! -f /swapfile ]; then
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        print_success "2GB swap file created"
    else
        print_success "Swap file already exists"
    fi
else
    print_success "Sufficient memory: ${TOTAL_MEM}MB"
fi

# Optimize system settings
print_status "Optimizing system settings..."
cat >> /etc/sysctl.conf << EOF

# Maninfini CRM optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
vm.swappiness = 10
EOF

sysctl -p

# Create system user for CRM
print_status "Creating system user for CRM..."
if ! id "maninfini" &>/dev/null; then
    useradd -r -s /bin/bash -d /var/www/CRMMANINFINI maninfini
    usermod -aG docker maninfini
    print_success "User 'maninfini' created"
else
    print_success "User 'maninfini' already exists"
fi

# Set up log rotation
print_status "Setting up log rotation..."
cat > /etc/logrotate.d/maninfini-crm << EOF
/var/www/CRMMANINFINI/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 maninfini maninfini
    postrotate
        systemctl reload maninfini-crm.service
    endscript
}
EOF

print_success "Log rotation configured"

# Final setup
print_status "Finalizing setup..."

# Start Docker service
systemctl start docker
systemctl enable docker

# Test Docker
if docker --version &> /dev/null; then
    print_success "Docker is working correctly"
else
    print_error "Docker installation failed"
    exit 1
fi

# Test Docker Compose
if docker-compose --version &> /dev/null; then
    print_success "Docker Compose is working correctly"
else
    print_error "Docker Compose installation failed"
    exit 1
fi

echo ""
print_success "🎉 Server setup completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Log out and log back in for Docker group changes to take effect"
echo "2. Navigate to /var/www/CRMMANINFINI"
echo "3. Run the deployment script: ./deploy-maninfini.sh"
echo ""
echo "🔧 What was installed:"
echo "  ✅ Docker & Docker Compose"
echo "  ✅ Nginx (web server)"
echo "  ✅ Certbot (SSL certificates)"
echo "  ✅ Firewall configuration"
echo "  ✅ System optimizations"
echo "  ✅ Log rotation"
echo "  ✅ Swap file (if needed)"
echo ""
echo "🌐 Your server is ready for Maninfini Automation CRM deployment!"
echo ""
echo "💡 Tip: You can now run:"
echo "  cd /var/www/CRMMANINFINI"
echo "  wget https://raw.githubusercontent.com/princejain756/CRMMANINFINI/main/deploy-maninfini.sh"
echo "  chmod +x deploy-maninfini.sh"
echo "  ./deploy-maninfini.sh"
