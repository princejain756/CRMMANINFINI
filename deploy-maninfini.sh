#!/bin/bash

# 🚀 Maninfini Automation CRM Deployment Script
# This script deploys your customized Twenty CRM on your server

set -e

echo "🚀 Starting Maninfini Automation CRM Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. For production, it's recommended to run as a regular user with sudo privileges."
    print_status "However, since you're deploying to production, we'll proceed with proper security measures."
    
    # Create a production user if it doesn't exist
    if ! id "maninfini" &>/dev/null; then
        print_status "Creating production user 'maninfini'..."
        useradd -m -s /bin/bash -d /var/www/CRMMANINFINI maninfini
        usermod -aG docker maninfini
        print_success "Production user 'maninfini' created"
    else
        print_success "Production user 'maninfini' already exists"
    fi
    
    # Set proper ownership
    chown -R maninfini:maninfini /var/www/CRMMANINFINI
    chmod 755 /var/www/CRMMANINFINI
fi

# Check dependencies
print_status "Checking dependencies..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git first."
    exit 1
fi

print_success "All dependencies are installed."

# Create deployment directory
DEPLOY_DIR="/var/www/CRMMANINFINI"
print_status "Creating deployment directory: $DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Clone your repository
if [ -d ".git" ]; then
    print_status "Repository already exists, pulling latest changes..."
    git pull origin main
else
    print_status "Cloning your repository..."
    # Remove any existing files first
    rm -rf * .[^.]* 2>/dev/null || true
    
    # Clone into current directory
    git clone https://github.com/princejain756/CRMMANINFINI.git .
fi

# Copy docker-compose files
print_status "Setting up Docker Compose configuration..."
cp packages/twenty-docker/docker-compose.yml ./
cp packages/twenty-docker/docker-compose.maninfini.yml ./

# Create production environment file
print_status "Creating production environment file..."
cat > .env << 'EOF'
# Production Environment Configuration for Maninfini Automation CRM

# Database Configuration
PG_DATABASE_USER=postgres
PG_DATABASE_PASSWORD=maninfini_secure_password_2024
PG_DATABASE_HOST=db
PG_DATABASE_PORT=5432

# Server Configuration
SERVER_URL=https://crm.maninfini.com
NODE_PORT=3000

# Redis Configuration
REDIS_URL=redis://redis:6379

# Security
APP_SECRET=maninfini_very_long_random_secret_key_2024_automation_crm

# Database Migrations
DISABLE_DB_MIGRATIONS=false
DISABLE_CRON_JOBS_REGISTRATION=false

# Storage Configuration
STORAGE_TYPE=local

# Email Configuration
EMAIL_FROM_ADDRESS=noreply@maninfini.com
EMAIL_FROM_NAME="Maninfini Automation CRM"
EMAIL_SYSTEM_ADDRESS=system@maninfini.com
EMAIL_DRIVER=smtp
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
# EMAIL_SMTP_USER=your-email@gmail.com
# EMAIL_SMTP_PASSWORD=your-app-password
EOF

print_warning "Please edit the .env file with your actual domain and email settings:"
print_status "  - Update SERVER_URL with your actual domain"
print_status "  - Update email SMTP settings if needed"
print_status "  - Update APP_SECRET with a truly random string"

# Generate secure passwords
print_status "Generating secure passwords..."
NEW_DB_PASSWORD=$(openssl rand -hex 32)
NEW_APP_SECRET=$(openssl rand -base64 64)

# Update .env with generated passwords
sed -i "s/maninfini_secure_password_2024/$NEW_DB_PASSWORD/g" .env
sed -i "s/maninfini_very_long_random_secret_key_2024_automation_crm/$NEW_APP_SECRET/g" .env

print_success "Secure passwords generated and updated in .env file."

# Create systemd service file
print_status "Creating systemd service for auto-startup..."
tee /etc/systemd/system/maninfini-crm.service > /dev/null << EOF
[Unit]
Description=Maninfini Automation CRM
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml down
TimeoutStartSec=0
User=maninfini
Group=maninfini
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable maninfini-crm.service

print_success "Systemd service created and enabled."

# Create backup script
print_status "Creating backup script..."
cat > backup.sh << 'EOF'
#!/bin/bash
# Backup script for Maninfini CRM

BACKUP_DIR="/var/www/CRMMANINFINI/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_DIR/backup_$DATE.sql"
docker-compose exec -T db pg_dump -U postgres default > "$BACKUP_DIR/backup_$DATE.sql"

echo "Backup completed: $BACKUP_DIR/backup_$DATE.sql"
EOF

chmod +x backup.sh

# Create update script
print_status "Creating update script..."
cat > update.sh << 'EOF'
#!/bin/bash
# Update script for Maninfini CRM

echo "Updating Maninfini CRM..."
git pull origin main

echo "Rebuilding and restarting services..."
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml down
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml build --no-cache
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml up -d

echo "Update completed!"
EOF

chmod +x update.sh

# Create nginx configuration template
print_status "Creating Nginx configuration template..."
cat > nginx-maninfini.conf << 'EOF'
# Nginx configuration for Maninfini Automation CRM
# Place this file in /etc/nginx/sites-available/ and create a symlink to sites-enabled/

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL Configuration (update with your certificate paths)
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Proxy to Twenty CRM
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check endpoint
    location /healthz {
        proxy_pass http://localhost:3000/healthz;
        access_log off;
    }
}
EOF

print_status "Nginx configuration template created: nginx-maninfini.conf"

# Create firewall configuration
print_status "Creating firewall configuration..."
cat > firewall-setup.sh << 'EOF'
#!/bin/bash
# Firewall setup for Maninfini CRM

echo "Setting up firewall rules..."

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Allow internal Docker communication
sudo ufw allow from 172.16.0.0/12

# Enable firewall
sudo ufw --force enable

echo "Firewall configured successfully!"
echo "Current rules:"
sudo ufw status numbered
EOF

chmod +x firewall-setup.sh

# Create monitoring script
print_status "Creating monitoring script..."
cat > monitor.sh << 'EOF'
#!/bin/bash
# Monitoring script for Maninfini CRM

echo "=== Maninfini CRM Status ==="
echo "Date: $(date)"
echo ""

echo "=== Docker Services ==="
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml ps
echo ""

echo "=== Service Health ==="
if curl -s http://localhost:3000/healthz > /dev/null; then
    echo "✅ CRM Server: Healthy"
else
    echo "❌ CRM Server: Unhealthy"
fi

echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

echo "=== Disk Usage ==="
df -h /opt/maninfini-crm
echo ""

echo "=== Recent Logs ==="
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml logs --tail=20 server
EOF

chmod +x monitor.sh

# Start the services
print_status "Building custom Maninfini image and starting services..."
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml build --no-cache
docker-compose -f docker-compose.yml -f docker-compose.maninfini.yml up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service status
if docker-compose ps | grep -q "Up"; then
    print_success "Services are starting up!"
else
    print_error "Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

# Final instructions
echo ""
print_success "🎉 Maninfini Automation CRM deployment completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Edit .env file with your actual domain and settings"
echo "2. Configure your domain DNS to point to this server"
echo "3. Set up SSL certificates for HTTPS"
echo "4. Configure Nginx using the provided template"
echo "5. Set up regular backups using: ./backup.sh"
echo ""
echo "🔧 Useful Commands:"
echo "  - Check status: ./monitor.sh"
echo "  - View logs: docker-compose logs -f"
echo "  - Update CRM: ./update.sh"
echo "  - Backup database: ./backup.sh"
echo "  - Restart services: docker-compose restart"
echo ""
echo "🌐 Your CRM will be available at: http://localhost:3000"
echo "   (Update SERVER_URL in .env and configure Nginx for domain access)"
echo ""
echo "📚 For production deployment, consider:"
echo "  - Setting up SSL certificates with Let's Encrypt"
echo "  - Configuring automated backups"
echo "  - Setting up monitoring and alerting"
echo "  - Configuring log rotation"
echo ""
print_success "Deployment completed successfully!"
