# Reloop Mail Server

A complete, portable mail server solution using Docker with PostgreSQL database integration. Based on the BillionMail project architecture.

## 🚀 Features

- **Postfix** - SMTP server with PostgreSQL integration
- **Dovecot** - IMAP/POP3 server with PostgreSQL authentication
- **Rspamd** - Advanced spam filtering
- **Redis** - Caching and session management
- **PostgreSQL** - Database for domains, mailboxes, and aliases
- **RoundCube** - Webmail interface
- **Nginx** - Reverse proxy with SSL termination
- **Portable** - Easy to move between servers
- **Complete Authentication** - User and alias handling

## 📋 Prerequisites

- Docker and Docker Compose
- Domain name with proper DNS records
- SSL certificates (optional, self-signed will be generated)

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd reloop
chmod +x setup.sh
./setup.sh
```

### 2. Configure Environment

Edit the `.env` file with your settings:

```bash
# Mail Server Configuration
MAIL_HOSTNAME=mail.yourdomain.com

# Database Configuration (local PostgreSQL included)
DB_NAME=reloop_mail
DB_USER=reloop_user
DB_PASSWORD=reloop_secure_password_2024

# Redis Configuration
REDIS_PASSWORD=reloop_redis_password_2024

# Mail Ports (customize if needed)
SMTP_PORT=25
IMAP_PORT=143
HTTP_PORT=80
HTTPS_PORT=443
```

### 3. Start Services

```bash
docker-compose up -d
```

## 📧 Services

| Service | Port | Description |
|---------|------|-------------|
| SMTP | 25 | Mail sending/receiving |
| SMTPS | 465 | Secure SMTP |
| Submission | 587 | Mail submission |
| IMAP | 143 | Mail access |
| IMAPS | 993 | Secure IMAP |
| POP3 | 110 | POP3 access |
| POP3S | 995 | Secure POP3 |
| Webmail | 80/443 | RoundCube web interface |
| PostgreSQL | 5432 | Database (internal) |
| Redis | 6379 | Caching (internal) |

## 🗄️ Database Schema

The mail server uses these tables:

- `domain` - Mail domains
- `mailbox` - Email accounts
- `alias` - Email forwarding
- `alias_domain` - Domain forwarding

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

## 🔧 Configuration

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

## 🌐 DNS Configuration

Set up these DNS records for your domain:

```
A     mail.yourdomain.com    → Your server IP
MX    yourdomain.com         → mail.yourdomain.com
SPF   yourdomain.com         → v=spf1 mx a ip4:YOUR_SERVER_IP ~all
DKIM  default._domainkey.yourdomain.com → (DKIM key)
DMARC _dmarc.yourdomain.com  → v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com
```

## 🔐 SSL Certificates

The setup script generates self-signed certificates. For production:

1. Replace `ssl/cert.pem` and `ssl/key.pem` with your certificates
2. Update Nginx configuration if needed
3. Ensure proper file permissions (600 for key, 644 for cert)

## 📊 Monitoring

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
```

### Test Mail Server

```bash
# Test SMTP
telnet localhost 25
EHLO mail.yourdomain.com

# Test IMAP
telnet localhost 143
a001 LOGIN username password
```

## 🔄 Portability

To move this mail server to another server:

1. Copy the entire `reloop` directory
2. Update `.env` file with new domain settings
3. Update DNS records to point to new server IP
4. Run `docker-compose up -d`

## 🛡️ Security

- All services run in isolated containers
- SSL/TLS encryption for all connections
- Spam filtering with Rspamd
- Proper file permissions
- Security headers in Nginx
- PostgreSQL authentication

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check database credentials in `.env`
   - Ensure PostgreSQL container is running
   - Verify database schema is loaded

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
   - Review Nginx logs: `docker-compose logs nginx`

### Useful Commands

```bash
# Rebuild containers
docker-compose build --no-cache

# Restart specific service
docker-compose restart postfix

# Check container logs
docker-compose logs -f

# Access container shell
docker-compose exec postfix bash
```

## 📝 License

This project is based on the BillionMail project and is licensed under AGPLv3.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review service logs
- Open an issue on GitHub
