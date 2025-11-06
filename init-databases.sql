-- TechTorque Microservice Database Initialization Script
-- Run this script once in PgAdmin or your preferred SQL client.

-- It's good practice to connect as a superuser (like 'postgres') to run this.

CREATE DATABASE techtorque;
CREATE DATABASE techtorque_vehicles;
CREATE DATABASE techtorque_appointments;
CREATE DATABASE techtorque_projects;
CREATE DATABASE techtorque_timelogs;
CREATE DATABASE techtorque_payments;
CREATE DATABASE techtorque_admin;
CREATE DATABASE techtorque_notification;

-- You also need to create the user that your applications will connect as.
-- The password here should match what's in your application.properties files.
-- The "CREATE USER" command might fail if the user already exists, which is okay.
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'techtorque') THEN

      CREATE USER techtorque WITH PASSWORD 'techtorque123';
   END IF;
END
$do$;

-- Grant privileges for the new user on all the created databases.
GRANT ALL PRIVILEGES ON DATABASE techtorque TO techtorque;
GRANT ALL PRIVILEGES ON DATABASE techtorque_vehicles TO techtorque;
GRANT ALL PRIVILEGES ON DATABASE techtorque_appointments TO techtorque;
GRANT ALL PRIVILEGES ON DATABASE techtorque_projects TO techtorque;
GRANT ALL PRIVILEGES ON DATABASE techtorque_timelogs TO techtorque;
GRANT ALL PRIVILEGES ON DATABASE techtorque_payments TO techtorque;
GRANT ALL PRIVILEGES ON DATABASE techtorque_admin TO techtorque;

-- A message to confirm completion
\echo 'All TechTorque databases and the techtorque user have been created successfully.'

-- ================================================================================
-- TECHTORQUE AUTHENTICATION SERVICE SCHEMA
-- ================================================================================
-- This section creates the core schema for the authentication service.
-- Note: If using Hibernate with ddl-auto=update, these will be auto-created.
-- This schema is provided for manual setup and documentation purposes.
-- ================================================================================

\c techtorque

-- Create sequence for ID generation
CREATE SEQUENCE IF NOT EXISTS hibernate_sequence START 1;

-- Create roles table
CREATE TABLE IF NOT EXISTS roles (
    id BIGINT PRIMARY KEY DEFAULT nextval('hibernate_sequence'),
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id BIGINT PRIMARY KEY DEFAULT nextval('hibernate_sequence'),
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create role_permissions junction table
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Create users table with EMAIL VERIFICATION fields
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY DEFAULT nextval('hibernate_sequence'),
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(500),
    profile_photo_url VARCHAR(500),
    enabled BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    email_verification_deadline TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user_roles junction table
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- Create verification_tokens table
CREATE TABLE IF NOT EXISTS verification_tokens (
    id VARCHAR(36) PRIMARY KEY,
    token VARCHAR(500) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expiry_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    token_type VARCHAR(50) NOT NULL,
    CHECK (token_type IN ('EMAIL_VERIFICATION', 'PASSWORD_RESET'))
);

-- Create refresh_tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    token VARCHAR(500) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expiry_date TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT false,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP NOT NULL
);

-- Create login_logs table
CREATE TABLE IF NOT EXISTS login_logs (
    id BIGINT PRIMARY KEY DEFAULT nextval('hibernate_sequence'),
    username VARCHAR(100) NOT NULL,
    success BOOLEAN NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP NOT NULL
);

-- Create login_locks table
CREATE TABLE IF NOT EXISTS login_locks (
    id BIGINT PRIMARY KEY DEFAULT nextval('hibernate_sequence'),
    username VARCHAR(100) NOT NULL UNIQUE,
    failed_attempts INT DEFAULT 0,
    lock_until TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGINT PRIMARY KEY DEFAULT nextval('hibernate_sequence'),
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    notifications_email BOOLEAN DEFAULT true,
    notifications_sms BOOLEAN DEFAULT false,
    notifications_push BOOLEAN DEFAULT false,
    language VARCHAR(10) DEFAULT 'en',
    reminders BOOLEAN DEFAULT true,
    updates BOOLEAN DEFAULT true,
    marketing BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ================================================================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);
CREATE INDEX IF NOT EXISTS idx_users_email_verification_deadline ON users(email_verification_deadline);
CREATE INDEX IF NOT EXISTS idx_users_enabled ON users(enabled);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Verification tokens indexes
CREATE INDEX IF NOT EXISTS idx_verification_tokens_token ON verification_tokens(token);
CREATE INDEX IF NOT EXISTS idx_verification_tokens_user_id ON verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_tokens_expiry ON verification_tokens(expiry_date);
CREATE INDEX IF NOT EXISTS idx_verification_tokens_type ON verification_tokens(token_type);

-- Refresh tokens indexes
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expiry ON refresh_tokens(expiry_date);

-- Login logs indexes
CREATE INDEX IF NOT EXISTS idx_login_logs_username ON login_logs(username);
CREATE INDEX IF NOT EXISTS idx_login_logs_created_at ON login_logs(created_at);

-- Login locks indexes
CREATE INDEX IF NOT EXISTS idx_login_locks_username ON login_locks(username);

-- ================================================================================
-- INSERT DEFAULT ROLES
-- ================================================================================

INSERT INTO roles (name) VALUES
    ('CUSTOMER'),
    ('EMPLOYEE'),
    ('ADMIN'),
    ('SUPER_ADMIN')
ON CONFLICT (name) DO NOTHING;

-- ================================================================================
-- INSERT DEFAULT PERMISSIONS
-- ================================================================================

INSERT INTO permissions (name, description) VALUES
    ('READ_USERS', 'Can view user information'),
    ('CREATE_USERS', 'Can create new users'),
    ('UPDATE_USERS', 'Can update user information'),
    ('DELETE_USERS', 'Can delete users'),
    ('READ_ROLES', 'Can view roles'),
    ('MANAGE_ROLES', 'Can assign/revoke roles'),
    ('VIEW_REPORTS', 'Can view system reports'),
    ('MANAGE_SYSTEM', 'Can manage system settings')
ON CONFLICT (name) DO NOTHING;

-- ================================================================================
-- ASSIGN DEFAULT PERMISSIONS TO ROLES
-- ================================================================================

-- Get role and permission IDs and assign permissions
DO $$
DECLARE
    customer_id BIGINT;
    employee_id BIGINT;
    admin_id BIGINT;
    super_admin_id BIGINT;
BEGIN
    -- Get role IDs
    SELECT id INTO customer_id FROM roles WHERE name = 'CUSTOMER';
    SELECT id INTO employee_id FROM roles WHERE name = 'EMPLOYEE';
    SELECT id INTO admin_id FROM roles WHERE name = 'ADMIN';
    SELECT id INTO super_admin_id FROM roles WHERE name = 'SUPER_ADMIN';

    -- Assign permissions to CUSTOMER role
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT customer_id, id FROM permissions WHERE name = 'READ_USERS'
    ON CONFLICT DO NOTHING;

    -- Assign permissions to EMPLOYEE role
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT employee_id, id FROM permissions WHERE name IN ('READ_USERS', 'VIEW_REPORTS')
    ON CONFLICT DO NOTHING;

    -- Assign permissions to ADMIN role
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT admin_id, id FROM permissions
    ON CONFLICT DO NOTHING;

    -- Assign all permissions to SUPER_ADMIN role
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT super_admin_id, id FROM permissions
    ON CONFLICT DO NOTHING;
END $$;

\echo 'TechTorque Authentication Service schema created successfully with email verification fields!'
\echo 'Note: If Hibernate ddl-auto is set to "update" or "create", the schema will be auto-updated on application startup.'
