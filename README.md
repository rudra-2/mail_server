# Reloop Mail Server

A complete, portable mail server solution using Docker with PostgreSQL database integration. Based on the BillionMail project architecture.

## Features

- **Postfix** - SMTP server with PostgreSQL integration
- **Dovecot** - IMAP/POP3 server with PostgreSQL authentication
- **Rspamd** - Advanced spam filtering
- **Redis** - Caching and session management
- **PostgreSQL** - External database support for domains, mailboxes, and aliases
- **Portable** - Easy to move between servers
- **Complete Authentication** - User and alias handling
- **Remote Database** - Support for external PostgreSQL servers
- **Direct SSL** - SSL/TLS handled directly by mail services

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/rudra-2/mail_server.git
cd mail_server

# 2. Run the setup script
chmod +x setup.sh
./setup.sh

# 3. Follow the prompts to configure your environment
# 4. Set up your remote PostgreSQL database
# 5. Configure DNS records
```

## Prerequisites

- Docker and Docker Compose
- Domain name with proper DNS records
- SSL certificates (optional, self-signed will be generated)
- Remote PostgreSQL database server

## VPS Setup Instructions

### 1. Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git ufw fail2ban

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if needed)
sudo ufw allow ssh

# Allow mail ports
sudo ufw allow 25/tcp   # SMTP
sudo ufw allow 465/tcp  # SMTPS
sudo ufw allow 587/tcp  # Submission
sudo ufw allow 143/tcp  # IMAP
sudo ufw allow 993/tcp  # IMAPS
sudo ufw allow 110/tcp  # POP3
sudo ufw allow 995/tcp  # POP3S

# Enable firewall
sudo ufw enable
```

### 3. DNS Configuration

Set up these DNS records for your domain:

```
A     mail.yourdomain.com    → Your VPS IP
MX    yourdomain.com         → mail.yourdomain.com (priority 10)
SPF   yourdomain.com         → v=spf1 mx a ip4:YOUR_VPS_IP ~all
DKIM  default._domainkey.yourdomain.com → (DKIM key)
DMARC _dmarc.yourdomain.com  → v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com
```

### 4. Clone and Setup

```bash
# Clone the repository
git clone <your-repo>
cd reloop

# Run the setup script
chmod +x setup.sh
./setup.sh
```

### 5. Configure Environment

The setup script will automatically create the `.env` file and prompt you to configure it. You'll need to set:

**Required Configuration:**
```bash
# Mail Server Configuration
MAIL_HOSTNAME=mail.yourdomain.com

# Database Configuration (External PostgreSQL)
DB_HOST=your_remote_postgresql_host
DB_NAME=reloop_mail
DB_USER=reloop_user
DB_PASSWORD=reloop_secure_password_2024

# Redis Configuration
REDIS_PASSWORD=reloop_redis_password_2024
```

### 6. SSL Certificates

The setup script will automatically generate self-signed certificates for testing.

**For production, replace with Let's Encrypt certificates:**
```bash
# Install certbot
sudo apt install certbot

# Generate certificates
sudo certbot certonly --standalone -d mail.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/mail.yourdomain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/mail.yourdomain.com/privkey.pem ssl/key.pem

# Set proper permissions
sudo chown $USER:$USER ssl/cert.pem ssl/key.pem
chmod 600 ssl/key.pem
chmod 644 ssl/cert.pem
```

### 7. Database Setup

**On your remote PostgreSQL server:**

```sql
-- Create database
CREATE DATABASE reloop_mail;

-- Create user
CREATE USER reloop_user WITH PASSWORD 'your_secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE reloop_mail TO reloop_user;

-- Connect to database and initialize schema
\c reloop_mail
\i database/init.sql

-- Add your domain
INSERT INTO domain (domain, a_record, create_time) 
VALUES ('yourdomain.com', 'YOUR_VPS_IP', extract(epoch from now()));

-- Add a test user (password: test123)
INSERT INTO mailbox (username, password, password_encode, full_name, maildir, local_part, domain, create_time) 
VALUES ('admin@yourdomain.com', '$1$test123', 'MD5-CRYPT', 'Admin User', 'yourdomain.com/admin/', 'admin', 'yourdomain.com', extract(epoch from now()));
```

### 8. Start Services

The setup script will automatically start all services. If you need to restart:

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 9. Verify Installation

```bash
# Test SMTP
telnet localhost 25
EHLO mail.yourdomain.com
QUIT

# Test IMAP
telnet localhost 143
a001 LOGIN admin@yourdomain.com test123
a002 LOGOUT
QUIT

# Test database connection
docker-compose exec postfix psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT * FROM domain;"
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| SMTP | 25 | Mail sending/receiving |
| SMTPS | 465 | Secure SMTP |
| Submission | 587 | Mail submission |
| IMAP | 143 | Mail access |
| IMAPS | 993 | Secure IMAP |
| POP3 | 110 | POP3 access |
| POP3S | 995 | Secure POP3 |
| Redis | 6379 | Caching (internal) |
| PostgreSQL | External | Database (remote server) |

## Database Schema

The mail server uses these tables:

- `domain` - Mail domains
- `mailbox` - Email accounts
- `alias` - Email forwarding
- `alias_domain` - Domain forwarding

## Remote Database Setup

### Prerequisites
- Remote PostgreSQL server accessible from your mail server
- PostgreSQL user with proper permissions
- Network connectivity on port 5432

### Database Initialization
1. Create the database on your remote PostgreSQL server:
   ```sql
   CREATE DATABASE reloop_mail;
   ```

2. Create a user with proper permissions:
   ```sql
   CREATE USER reloop_user WITH PASSWORD 'your_secure_password';
   GRANT ALL PRIVILEGES ON DATABASE reloop_mail TO reloop_user;
   ```

3. Initialize the database schema:
   ```bash
   psql -h your_remote_host -U reloop_user -d reloop_mail -f database/init.sql
   ```

### Network Configuration
Ensure your firewall allows connections from your mail server to the remote PostgreSQL server on port 5432.

### Sample Data

```sql
-- Add a domain
INSERT INTO domain (domain, a_record, create_time) 
VALUES ('yourdomain.com', 'YOUR_SERVER_IP', extract(epoch from now()));

-- Add a mailbox (password should be MD5-CRYPT hashed)
-- Use: openssl passwd -1 "your_password" to generate the hash
INSERT INTO mailbox (username, password, password_encode, full_name, maildir, local_part, domain, create_time) 
VALUES ('admin@yourdomain.com', '$1$hashedpassword', 'MD5-CRYPT', 'Admin User', 'yourdomain.com/admin/', 'admin', 'yourdomain.com', extract(epoch from now()));

-- Add an alias (email forwarding)
INSERT INTO alias (address, goto, domain, create_time) 
VALUES ('info@yourdomain.com', 'admin@yourdomain.com', 'yourdomain.com', extract(epoch from now()));
```

## Mail Client Configuration

Since this mail server doesn't include a webmail interface, users should configure desktop or mobile mail clients:

### Desktop Mail Clients
- **Thunderbird** - Free, open-source email client
- **Outlook** - Microsoft email client
- **Apple Mail** - macOS email client
- **Evolution** - Linux email client

### Mobile Mail Apps
- **Gmail app** - Android/iOS
- **Apple Mail** - iOS
- **Outlook app** - Android/iOS
- **K-9 Mail** - Android (open-source)

### Configuration Settings
```
SMTP Settings:
- Server: your_mail_server_ip
- Port: 587 (Submission) or 465 (SMTPS)
- Security: STARTTLS or SSL/TLS
- Authentication: Username and Password

IMAP Settings:
- Server: your_mail_server_ip
- Port: 143 (IMAP) or 993 (IMAPS)
- Security: STARTTLS or SSL/TLS
- Authentication: Username and Password
```

## Configuration

### Postfix Configuration

Main configuration: `config/postfix/main.cf`
- Virtual domains via PostgreSQL
- TLS/SSL support
- Rspamd integration
- Dovecot SASL authentication

### Dovecot Configuration

Main configuration: `config/dovecot/dovecot.conf`
- PostgreSQL authentication
- Maildir storage
- Sieve filtering
- SSL/TLS support

### Rspamd Configuration

Main configuration: `config/rspamd/rspamd.conf`
- Spam filtering rules
- Redis integration
- Postfix milter integration

## SSL Certificates

For production use, you should replace the self-signed certificates:

1. Replace `ssl/cert.pem` and `ssl/key.pem` with your certificates
2. Ensure proper file permissions (600 for key, 644 for cert)
3. Restart services after certificate changes

Note: SSL certificates are used by Postfix and Dovecot for secure connections.

## Management

### Basic Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart all services
docker-compose restart

# View running services
docker-compose ps

# View service logs
docker-compose logs [service_name]

# Follow logs in real-time
docker-compose logs -f [service_name]
```

## Monitoring

### Check Service Status

```bash
docker-compose ps
```

### View Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs postfix
docker-compose logs dovecot
docker-compose logs rspamd

# Follow logs in real-time
docker-compose logs -f
```

### Test Mail Server

```bash
# Test SMTP
telnet localhost 25
EHLO mail.yourdomain.com

# Test SMTP Authentication (port 587)
telnet localhost 587
EHLO mail.yourdomain.com
AUTH LOGIN

# Test IMAP
telnet localhost 143
a001 LOGIN username password

# Test database connection
docker-compose exec postfix psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT * FROM domain;"
```

## Portability

To move this mail server to another server:

1. Copy the entire `reloop` directory
2. Update `.env` file with new domain settings
3. Update DNS records to point to new server IP
4. Run `docker-compose up -d`

## Security

- All services run in isolated containers
- SSL/TLS encryption for all connections
- Spam filtering with Rspamd
- Proper file permissions
- PostgreSQL authentication
- Firewall protection with UFW

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check database credentials in `.env`
   - Ensure remote PostgreSQL server is accessible
   - Verify database schema is loaded
   - Test connection: `docker-compose exec postfix psql -h $DB_HOST -U $DB_USER -d $DB_NAME`

2. **Mail Not Received**
   - Check DNS records
   - Verify firewall settings
   - Check Postfix logs: `docker-compose logs postfix`

3. **Authentication Failed**
   - Verify mailbox exists in database
   - Check password format (MD5-CRYPT)
   - Review Dovecot logs: `docker-compose logs dovecot`

4. **SSL Issues**
   - Verify certificate files exist
   - Check file permissions
   - Review service logs

### Useful Commands

```bash
# Rebuild containers
docker-compose build --no-cache

# Restart specific service
docker-compose restart postfix

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Check container logs
docker-compose logs -f

# Access container shell
docker-compose exec postfix bash
docker-compose exec dovecot bash
```

## License

This project is based on the BillionMail project and is licensed under AGPLv3.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting section
- Review service logs
- Open an issue on GitHub
