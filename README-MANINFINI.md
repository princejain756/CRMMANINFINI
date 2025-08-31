# 🚀 Maninfini Automation CRM

A customized version of Twenty CRM, rebranded and optimized for automation companies and workflows.

## ✨ What's New

This CRM has been completely customized from the original Twenty CRM with:

- **🏢 Workspace**: "Maninfini Automation" instead of "YCombinator"
- **🎨 Logo**: Custom logo for your automation business
- **🤖 AI Assistant**: Updated messages focused on automation trends
- **🏷️ Branding**: All references updated to reflect automation focus
- **🔗 Subdomain**: Changed to "maninfini" for consistency

## 🎯 Features

- **Contact Management**: Organize leads, prospects, and customers
- **Company Tracking**: Monitor automation companies and their performance
- **Deal Pipeline**: Track opportunities and sales processes
- **Task Management**: Organize workflows and automation projects
- **AI Assistant**: Get insights on automation trends and portfolio performance
- **Custom Fields**: Adapt the CRM to your specific automation needs
- **API Integration**: Connect with your existing automation tools

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
# On your server
wget https://raw.githubusercontent.com/princejain756/CRMMANINFINI/main/server-setup.sh
chmod +x server-setup.sh
sudo ./server-setup.sh

# After server setup
cd /opt/maninfini-crm
wget https://raw.githubusercontent.com/princejain756/CRMMANINFINI/main/deploy-maninfini.sh
chmod +x deploy-maninfini.sh
./deploy-maninfini.sh
```

### Option 2: Local Development

```bash
# Clone the repository
git clone https://github.com/princejain756/CRMMANINFINI.git
cd CRMMANINFINI

# Start services
make postgres-on-docker
make redis-on-docker

# Reset database with new configuration
export SERVER_URL=http://localhost:3000
export PG_DATABASE_URL=postgres://postgres:postgres@localhost:5432/default
npx nx database:reset twenty-server

# Start development server
yarn start
```

## 🔧 Server Requirements

- **OS**: Ubuntu 20.04+ or CentOS 8+
- **RAM**: Minimum 4GB, recommended 8GB+
- **Storage**: Minimum 20GB, recommended 50GB+
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

## 📁 Project Structure

```
CRMMANINFINI/
├── packages/
│   ├── twenty-front/          # React frontend
│   ├── twenty-server/         # NestJS backend
│   ├── twenty-ui/             # Shared UI components
│   └── twenty-docker/         # Docker configuration
├── deploy-maninfini.sh        # Main deployment script
├── server-setup.sh            # Server preparation script
├── DEPLOYMENT.md              # Detailed deployment guide
└── README-MANINFINI.md        # This file
```

## 🌐 Access

After deployment, your CRM will be available at:
- **Local**: http://localhost:3000
- **Production**: https://your-domain.com (after domain configuration)

## 🔐 Default Login

- **Email**: maninfini@maninfini.com
- **Password**: maninfini

## 📊 AI Assistant Features

The AI assistant has been customized to help with:
- Automation industry trends analysis
- Portfolio company performance insights
- Workflow optimization recommendations
- Automation tool integration suggestions

## 🔄 Updates & Maintenance

### Regular Updates
```bash
cd /opt/maninfini-crm/CRMMANINFINI
./update.sh
```

### Database Backups
```bash
./backup.sh
```

### Health Monitoring
```bash
./monitor.sh
```

## 🛠️ Customization

### Adding New Fields
1. Modify the database schema in `packages/twenty-server/src/engine/`
2. Update the frontend components in `packages/twenty-front/src/modules/`
3. Regenerate GraphQL types: `npx nx run twenty-front:graphql:generate`

### Branding Changes
1. Update logo in `packages/twenty-front/public/images/`
2. Modify seed data in `packages/twenty-server/src/engine/workspace-manager/dev-seeder/`
3. Reset database to apply changes

## 📚 Documentation

- **Deployment Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Twenty CRM Docs**: https://twenty.com/docs
- **API Reference**: Available at `/open-api/core` after deployment

## 🤝 Support

For issues or questions:
1. Check the logs: `docker-compose logs -f`
2. Review the deployment guide
3. Check Twenty CRM documentation
4. Open an issue on GitHub

## 🔒 Security

- All passwords are automatically generated
- Firewall rules are configured automatically
- SSL certificates can be set up with Let's Encrypt
- Regular security updates are recommended

## 📈 Performance

- Optimized for automation workflows
- Database indexing for fast searches
- Caching for improved response times
- Resource monitoring included

## 🎉 What's Next?

After deployment, consider:
- Setting up SSL certificates
- Configuring automated backups
- Setting up monitoring and alerting
- Integrating with your existing automation tools
- Customizing fields for your specific use case

---

**Built with ❤️ for the automation industry**

Your Maninfini Automation CRM is ready to streamline your business processes!
