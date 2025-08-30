#!/bin/bash

# Reloop Mail Server SASL Authentication Test Script
# ==================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to test SASL authentication
test_sasl_auth() {
    print_header "Testing SASL Authentication"
    
    # Check if containers are running
    print_status "Checking if containers are running..."
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Containers are not running. Please start them first:"
        echo "  docker-compose up -d"
        exit 1
    fi
    
    # Test SMTP SASL authentication
    print_status "Testing SMTP SASL authentication on port 587..."
    
    # Create a test script for SASL authentication
    cat > /tmp/test_sasl.txt << 'EOF'
EHLO test.example.com
AUTH LOGIN
dGVzdEBleGFtcGxlLmNvbQ==
dGVzdHBhc3N3b3Jk
MAIL FROM:<test@example.com>
RCPT TO:<test@example.com>
DATA
Subject: Test SASL Authentication

This is a test message to verify SASL authentication is working.
.
QUIT
EOF
    
    # Test SASL authentication
    if timeout 10 bash -c "telnet localhost 587 < /tmp/test_sasl.txt"; then
        print_status "SASL authentication test completed"
    else
        print_warning "SASL authentication test failed (this is expected without valid credentials)"
    fi
    
    # Test SMTP with valid credentials (if available)
    print_status "Testing SMTP with valid credentials..."
    echo "To test with valid credentials, you need to:"
    echo "1. Create a user in the database"
    echo "2. Use a mail client to connect to SMTP port 587"
    echo "3. Enable STARTTLS and authentication"
    
    # Test Dovecot SASL socket
    print_status "Testing Dovecot SASL socket..."
    if docker-compose exec dovecot ls -la /var/spool/postfix/private/auth 2>/dev/null; then
        print_status "Dovecot SASL socket exists"
    else
        print_error "Dovecot SASL socket not found"
    fi
    
    # Test Postfix SASL configuration
    print_status "Testing Postfix SASL configuration..."
    if docker-compose exec postfix postconf smtpd_sasl_type; then
        print_status "Postfix SASL type: $(docker-compose exec postfix postconf smtpd_sasl_type | cut -d'=' -f2)"
    fi
    
    if docker-compose exec postfix postconf smtpd_sasl_path; then
        print_status "Postfix SASL path: $(docker-compose exec postfix postconf smtpd_sasl_path | cut -d'=' -f2)"
    fi
    
    # Test sender login maps
    print_status "Testing sender login maps..."
    if docker-compose exec postfix postconf smtpd_sender_login_maps; then
        print_status "Sender login maps: $(docker-compose exec postfix postconf smtpd_sender_login_maps | cut -d'=' -f2)"
    fi
    
    # Cleanup
    rm -f /tmp/test_sasl.txt
    
    print_status "SASL authentication tests completed!"
}

# Function to show SASL configuration
show_sasl_config() {
    print_header "SASL Configuration Summary"
    
    echo "Postfix SASL Configuration:"
    echo "=========================="
    docker-compose exec postfix postconf | grep -E "(smtpd_sasl|smtpd_sender)" || true
    
    echo ""
    echo "Dovecot SASL Configuration:"
    echo "==========================="
    docker-compose exec dovecot doveconf | grep -E "(auth_mechanisms|disable_plaintext)" || true
    
    echo ""
    echo "SASL Socket Status:"
    echo "==================="
    docker-compose exec dovecot ls -la /var/spool/postfix/private/ || true
}

# Function to create test user
create_test_user() {
    print_header "Creating Test User for SASL Testing"
    
    read -p "Enter domain name (e.g., example.com): " DOMAIN
    read -p "Enter username (e.g., test): " USERNAME
    read -s -p "Enter password: " PASSWORD
    echo ""
    
    # Generate password hash
    PASSWORD_HASH=$(docker-compose exec postgresql openssl passwd -1 "$PASSWORD")
    
    # Create domain
    docker-compose exec postgresql psql -U reloop_user reloop_mail -c "
    INSERT INTO domain (domain, a_record, create_time) 
    VALUES ('$DOMAIN', '127.0.0.1', extract(epoch from now()))
    ON CONFLICT (domain) DO NOTHING;"
    
    # Create user
    docker-compose exec postgresql psql -U reloop_user reloop_mail -c "
    INSERT INTO mailbox (username, password, password_encode, full_name, maildir, local_part, domain, create_time) 
    VALUES ('$USERNAME@$DOMAIN', '$PASSWORD_HASH', 'MD5-CRYPT', 'Test User', '$DOMAIN/$USERNAME/', '$USERNAME', '$DOMAIN', extract(epoch from now()))
    ON CONFLICT (username) DO NOTHING;"
    
    print_status "Test user created: $USERNAME@$DOMAIN"
    print_status "You can now test SASL authentication with these credentials"
}

# Main script logic
main() {
    case "$1" in
        test)
            test_sasl_auth
            ;;
        config)
            show_sasl_config
            ;;
        create-user)
            create_test_user
            ;;
        help|--help|-h)
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  test        - Test SASL authentication"
            echo "  config      - Show SASL configuration"
            echo "  create-user - Create a test user for SASL testing"
            echo "  help        - Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            echo "Available commands: test, config, create-user, help"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
