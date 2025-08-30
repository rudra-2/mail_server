-- Reloop Mail Server Database Schema
-- ===================================
-- This schema is based on the BillionMail project structure

-- Domain table for mail domains
CREATE TABLE IF NOT EXISTS domain (
    domain varchar(255) NOT NULL,
    a_record varchar(255) NOT NULL DEFAULT '',
    mailboxes int NOT NULL DEFAULT 50,
    mailbox_quota BIGINT NOT NULL DEFAULT 5368709120,
    quota BIGINT NOT NULL DEFAULT 10737418240,
    rate_limit INT DEFAULT 12,
    create_time INT NOT NULL default 0,
    active SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (domain)
);

-- Mailbox table for email accounts
CREATE TABLE IF NOT EXISTS mailbox (
    username varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    password_encode varchar(255) NOT NULL,
    full_name varchar(255) NOT NULL,
    is_admin smallint NOT NULL DEFAULT 0,
    maildir varchar(255) NOT NULL,
    quota bigint NOT NULL DEFAULT 0,
    local_part varchar(255) NOT NULL,
    domain varchar(255) NOT NULL,
    create_time int NOT NULL default 0,
    update_time int NOT NULL default 0,
    active SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (username)
);

-- Alias table for email forwarding
CREATE TABLE IF NOT EXISTS alias (
    address varchar(255) NOT NULL,
    goto text NOT NULL,
    domain varchar(255) NOT NULL,
    create_time int NOT NULL default 0,
    update_time int NOT NULL default 0,
    active smallint NOT NULL DEFAULT 1,
    PRIMARY KEY (address)
);

-- Alias domain table for domain forwarding
CREATE TABLE IF NOT EXISTS alias_domain (
    alias_domain varchar(255) NOT NULL, 
    target_domain varchar(255) NOT NULL,
    create_time int NOT NULL default 0,
    update_time int NOT NULL default 0,
    active smallint NOT NULL DEFAULT 1,
    PRIMARY KEY (alias_domain)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mailbox_domain ON mailbox(domain);
CREATE INDEX IF NOT EXISTS idx_mailbox_active ON mailbox(active);
CREATE INDEX IF NOT EXISTS idx_alias_domain ON alias(domain);
CREATE INDEX IF NOT EXISTS idx_alias_active ON alias(active);
CREATE INDEX IF NOT EXISTS idx_domain_active ON domain(active);

-- Insert sample data for testing
-- Uncomment and modify these lines to create initial test data
/*
INSERT INTO domain (domain, a_record, create_time) 
VALUES ('yourdomain.com', 'YOUR_SERVER_IP', extract(epoch from now()));

-- Create a test mailbox (password should be MD5-CRYPT hashed)
-- Use: openssl passwd -1 "your_password" to generate the hash
INSERT INTO mailbox (username, password, password_encode, full_name, maildir, local_part, domain, create_time) 
VALUES ('admin@yourdomain.com', '$1$hashedpassword', 'MD5-CRYPT', 'Admin User', 'yourdomain.com/admin/', 'admin', 'yourdomain.com', extract(epoch from now()));
*/
