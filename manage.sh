#!/bin/bash

# Reloop Mail Server Management Script
# ====================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show help
show_help() {
    print_header "Reloop Mail Server Management"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  status      - Show service status"
    echo "  logs        - Show logs for all services"
    echo "  logs [SERVICE] - Show logs for specific service"
    echo "  shell [SERVICE] - Access shell in specific container"
    echo "  backup      - Create backup of data and configuration"
    echo "  restore     - Restore from backup"
    echo "  update      - Update containers and rebuild"
    echo "  clean       - Clean up unused containers and images"
    echo "  test        - Test mail server functionality"
    echo "  help        - Show this help message"
    echo ""
    echo "Services: postfix, dovecot, rspamd, redis, postgresql, webmail, nginx"
    echo ""
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or not available"
        exit 1
    fi
}

# Function to start services
start_services() {
    print_status "Starting Reloop Mail Server..."
    docker-compose up -d
    print_status "Services started successfully!"
}

# Function to stop services
stop_services() {
    print_status "Stopping Reloop Mail Server..."
    docker-compose down
    print_status "Services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_status "Restarting Reloop Mail Server..."
    docker-compose restart
    print_status "Services restarted successfully!"
}

# Function to show status
show_status() {
    print_header "Service Status"
    docker-compose ps
}

# Function to show logs
show_logs() {
    if [ -z "$1" ]; then
        print_header "All Services Logs"
        docker-compose logs --tail=50
    else
        print_header "Logs for $1"
        docker-compose logs --tail=50 "$1"
    fi
}

# Function to access shell
access_shell() {
    if [ -z "$1" ]; then
        print_error "Please specify a service name"
        echo "Available services: postfix, dovecot, rspamd, redis, postgresql, webmail, nginx"
        exit 1
    fi
    print_status "Accessing shell in $1 container..."
    docker-compose exec "$1" bash
}

# Function to create backup
create_backup() {
    print_status "Creating backup..."
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup data directories
    cp -r data "$BACKUP_DIR/"
    cp -r config "$BACKUP_DIR/"
    cp -r ssl "$BACKUP_DIR/"
    cp .env "$BACKUP_DIR/"
    cp docker-compose.yml "$BACKUP_DIR/"
    
    # Create database dump
    docker-compose exec postgresql pg_dump -U reloop_user reloop_mail > "$BACKUP_DIR/database.sql"
    
    # Create archive
    tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
    rm -rf "$BACKUP_DIR"
    
    print_status "Backup created: ${BACKUP_DIR}.tar.gz"
}

# Function to restore from backup
restore_backup() {
    if [ -z "$1" ]; then
        print_error "Please specify backup file"
        echo "Usage: $0 restore <backup_file.tar.gz>"
        exit 1
    fi
    
    print_warning "This will overwrite current data. Are you sure? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    print_status "Restoring from backup: $1"
    
    # Extract backup
    tar -xzf "$1"
    BACKUP_DIR=$(basename "$1" .tar.gz)
    
    # Stop services
    docker-compose down
    
    # Restore data
    rm -rf data config ssl
    cp -r "$BACKUP_DIR"/data .
    cp -r "$BACKUP_DIR"/config .
    cp -r "$BACKUP_DIR"/ssl .
    cp "$BACKUP_DIR"/.env .
    cp "$BACKUP_DIR"/docker-compose.yml .
    
    # Start services
    docker-compose up -d
    
    # Restore database
    docker-compose exec -T postgresql psql -U reloop_user reloop_mail < "$BACKUP_DIR/database.sql"
    
    # Cleanup
    rm -rf "$BACKUP_DIR"
    
    print_status "Restore completed successfully!"
}

# Function to update containers
update_containers() {
    print_status "Updating containers..."
    docker-compose pull
    docker-compose build --no-cache
    docker-compose up -d
    print_status "Update completed!"
}

# Function to clean up
clean_up() {
    print_status "Cleaning up unused containers and images..."
    docker system prune -f
    docker image prune -f
    print_status "Cleanup completed!"
}

# Function to test mail server
test_mail_server() {
    print_header "Testing Mail Server"
    
    # Check if services are running
    print_status "Checking service status..."
    docker-compose ps
    
    # Test SMTP
    print_status "Testing SMTP connection..."
    if timeout 5 bash -c "</dev/tcp/localhost/25"; then
        print_status "SMTP (port 25) is accessible"
    else
        print_error "SMTP (port 25) is not accessible"
    fi
    
    # Test IMAP
    print_status "Testing IMAP connection..."
    if timeout 5 bash -c "</dev/tcp/localhost/143"; then
        print_status "IMAP (port 143) is accessible"
    else
        print_error "IMAP (port 143) is not accessible"
    fi
    
    # Test web interface
    print_status "Testing web interface..."
    if timeout 5 bash -c "</dev/tcp/localhost/80"; then
        print_status "Web interface (port 80) is accessible"
    else
        print_error "Web interface (port 80) is not accessible"
    fi
    
    print_status "Testing completed!"
}

# Main script logic
main() {
    check_docker_compose
    
    case "$1" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        shell)
            access_shell "$2"
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "$2"
            ;;
        update)
            update_containers
            ;;
        clean)
            clean_up
            ;;
        test)
            test_mail_server
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
