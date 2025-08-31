# 🚀 Maninfini Automation CRM - Deployment Guide

## 📋 Overview

This guide will help you deploy your customized Twenty CRM (renamed to Maninfini Automation) on your server. All changes have been successfully pushed to your GitHub repository: https://github.com/princejain756/CRMMANINFINI

## ✨ What's Been Customized

- **Workspace Name**: Changed from "YCombinator" to "Maninfini Automation"
- **Logo**: Updated with your custom logo
- **AI Assistant**: Updated messages to reflect automation focus
- **Subdomain**: Changed from "yc" to "maninfini"
- **Company Names**: Updated to automation-focused companies

## 🐳 Deployment Options

### Option 1: Automated Deployment (Recommended)

Use the provided deployment script for a complete setup:

```bash
# Download the deployment script
wget https://raw.githubusercontent.com/princejain756/CRMMANINFINI/main/deploy-maninfini.sh

# Make it executable
chmod +x deploy-maninfini.sh

# Run the deployment
sudo ./deploy-maninfini.sh
```

### Option 2: Manual Docker Compose Deployment

1. **Clone your repository**:
   ```bash
   git clone https://github.com/princejain756/CRMMANINFINI.git
   cd CRMMANINFINI
   ```

2. **Set up environment**:
   ```bash
   cp packages/twenty-docker/docker-compose.yml ./
   cp packages/twenty-docker/.env.example .env
   ```

3. **Edit .env file** with your settings:
   ```bash
   nano .env
   ```

4. **Start services**:
   ```bash
   docker-compose up -d
   ```

## 🔧 Server Requirements

- **OS**: Ubuntu 20.04+ or CentOS 8+ (recommended)
- **RAM**: Minimum 4GB, recommended 8GB+
- **Storage**: Minimum 20GB, recommended 50GB+
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

## 📁 File Structure After Deployment

```
/opt/maninfini-crm/
├── CRMMANINFINI/           # Your CRM code
├── .env                     # Environment configuration
├── docker-compose.yml       # Docker services
├── backup.sh               # Database backup script
├── update.sh               # Update script
├── monitor.sh              # Monitoring script
├── firewall-setup.sh       # Firewall configuration
└── nginx-maninfini.conf    # Nginx template
```

## 🌐 Domain Configuration

1. **Update DNS**: Point your domain to your server's IP address
2. **Edit .env**: Update `SERVER_URL` with your domain
3. **Configure Nginx**: Use the provided template
4. **SSL Setup**: Install Let's Encrypt certificates

## 🔐 Security Configuration

The deployment script automatically:
- Generates secure random passwords
- Sets up firewall rules
- Creates systemd service for auto-startup
- Configures secure environment variables

## 📊 Monitoring & Maintenance

### Check Status
```bash
./monitor.sh
```

### View Logs
```bash
docker-compose logs -f
```

### Backup Database
```bash
./backup.sh
```

### Update CRM
```bash
./update.sh
```

## 🚨 Troubleshooting

### Common Issues

1. **Port 3000 already in use**:
   ```bash
   sudo lsof -i :3000
   sudo kill -9 <PID>
   ```

2. **Database connection failed**:
   ```bash
   docker-compose logs db
   docker-compose restart db
   ```

3. **Services not starting**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Log Locations
- **Application logs**: `docker-compose logs -f`
- **Database logs**: `docker-compose logs -f db`
- **System logs**: `journalctl -u maninfini-crm.service`

## 🔄 Updates & Maintenance

### Regular Updates
```bash
cd /opt/maninfini-crm/CRMMANINFINI
./update.sh
```

### Database Backups
```bash
# Manual backup
./backup.sh

# Automated backups (add to crontab)
0 2 * * * /opt/maninfini-crm/CRMMANINFINI/backup.sh
```

### Health Checks
```bash
# Check service health
curl http://localhost:3000/healthz

# Monitor resources
./monitor.sh
```

## 📞 Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify environment variables in `.env`
3. Ensure all ports are accessible
4. Check Docker service status: `systemctl status docker`

## 🎯 Production Checklist

- [ ] Domain DNS configured
- [ ] SSL certificates installed
- [ ] Firewall configured
- [ ] Backup strategy implemented
- [ ] Monitoring set up
- [ ] Log rotation configured
- [ ] Security updates enabled
- [ ] Performance monitoring active

## 🚀 Quick Start Commands

```bash
# Deploy everything
sudo ./deploy-maninfini.sh

# Check status
./monitor.sh

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Update CRM
./update.sh
```

---

**Your Maninfini Automation CRM is ready to deploy! 🎉**

For additional help, refer to the Twenty CRM documentation or check the logs for specific error messages.
