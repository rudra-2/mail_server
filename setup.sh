#!/bin/bash

# Reloop Mail Server Setup Script
# ===============================

set -e

echo "🚀 Setting up Reloop Mail Server..."
echo "==================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root"
   echo "Please run as a regular user with sudo privileges"
   exit 1
fi

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Run: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
fi

# Check for Docker Compose V2 (preferred) or V1
if docker compose version &> /dev/null; then
    echo "✅ Docker Compose V2 detected"
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose V1 detected"
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Run: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running or not accessible"
    echo "Please start Docker and ensure your user is in the docker group"
    echo "Run: sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p data/{redis,rspamd,vmail,postfix}
mkdir -p logs/{postfix,dovecot,rspamd}
mkdir -p ssl
echo "✅ Directories created"
echo ""

# Generate SSL certificates if they don't exist
if [ ! -f ssl/cert.pem ] || [ ! -f ssl/key.pem ]; then
    echo "🔐 Generating self-signed SSL certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Reloop/CN=mail.localhost"
    
    # Set proper permissions
    chmod 600 ssl/key.pem
    chmod 644 ssl/cert.pem
    echo "✅ Self-signed certificates generated"
    echo "⚠️  For production, replace with proper certificates"
else
    echo "✅ SSL certificates already exist"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  IMPORTANT: Please edit .env file with your settings:"
    echo "   - Set MAIL_HOSTNAME to your domain"
    echo "   - Configure your remote PostgreSQL database"
    echo "   - Update Redis password"
    echo ""
    echo "   Run: nano .env"
    echo ""
    read -p "Press Enter after you've configured the .env file..."
else
    echo "✅ .env file already exists"
fi

# Check if .env is properly configured
if ! grep -q "your_remote_postgresql_host" .env; then
    echo "✅ .env file appears to be configured"
else
    echo "⚠️  .env file still contains default values"
    echo "Please configure it before continuing"
    exit 1
fi

# Build and start containers
echo "🐳 Building and starting containers..."
$DOCKER_COMPOSE_CMD build --no-cache
$DOCKER_COMPOSE_CMD up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
$DOCKER_COMPOSE_CMD ps

echo ""
echo "🔍 Checking service health..."

# Check if services are running
if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
    echo "✅ All services are running"
else
    echo "❌ Some services failed to start"
    echo "Check logs with: $DOCKER_COMPOSE_CMD logs"
    exit 1
fi

echo ""
echo "🎉 Reloop Mail Server setup complete!"
echo ""
echo "📧 Mail Server Information:"
echo "   SMTP: localhost:25 (or your server IP)"
echo "   SMTPS: localhost:465"
echo "   Submission: localhost:587"
echo "   IMAP: localhost:143"
echo "   IMAPS: localhost:993"
echo "   POP3: localhost:110"
echo "   POP3S: localhost:995"
echo ""
echo "📋 Next steps:"
echo "   1. Configure your DNS records (A, MX, SPF, DKIM, DMARC)"
echo "   2. Set up your remote PostgreSQL database"
echo "   3. Add users to your database"
echo "   4. Test mail client connections"
echo "   5. Monitor logs: docker-compose logs -f"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: $DOCKER_COMPOSE_CMD logs -f"
echo "   Stop services: $DOCKER_COMPOSE_CMD down"
echo "   Restart services: $DOCKER_COMPOSE_CMD restart"
echo "   Check status: $DOCKER_COMPOSE_CMD ps"
echo ""
echo "📚 For detailed setup instructions, check the README.md file"
