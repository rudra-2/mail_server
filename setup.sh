#!/bin/bash

# Reloop Mail Server Setup Script
# ===============================

set -e

echo "🚀 Setting up Reloop Mail Server..."

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p data/{redis,rspamd,vmail,postfix,webmail,postgresql}
mkdir -p logs/{postfix,dovecot,rspamd,nginx}
mkdir -p ssl

# Generate SSL certificates if they don't exist
if [ ! -f ssl/cert.pem ] || [ ! -f ssl/key.pem ]; then
    echo "🔐 Generating self-signed SSL certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Reloop/CN=mail.localhost"
fi

# Set proper permissions
echo "🔒 Setting permissions..."
chmod 600 ssl/key.pem
chmod 644 ssl/cert.pem

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your domain settings"
    echo "   Then run: docker-compose up -d"
else
    echo "✅ .env file already exists"
fi

# Build and start containers
echo "🐳 Building and starting containers..."
docker-compose build
docker-compose up -d

echo "✅ Reloop Mail Server setup complete!"
echo ""
echo "📧 Services:"
echo "   - SMTP: localhost:25 (or custom port in .env)"
echo "   - IMAP: localhost:143 (or custom port in .env)"
echo "   - Webmail: https://localhost/webmail"
echo "   - Database: localhost:5432 (or custom port in .env)"
echo ""
echo "📋 Next steps:"
echo "   1. Edit .env file with your domain settings"
echo "   2. Run: docker-compose up -d"
echo "   3. Set up DNS records for your domain"
echo "   4. Create mail accounts in the database"
echo ""
echo "📚 For more information, check the README.md file"
