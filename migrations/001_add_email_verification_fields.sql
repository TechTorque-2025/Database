-- Migration: Add Email Verification Fields to Users Table
-- Date: 2025-11-06
-- Purpose: Add email verification tracking columns to support the new email verification feature
-- This allows users to sign in immediately but requires verification within 7 days

-- Add email_verified column
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;

-- Add email_verification_deadline column
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_deadline TIMESTAMP;

-- Update existing users to have a deadline of 7 days from now (they can verify anytime)
UPDATE users
SET email_verification_deadline = NOW() + INTERVAL '7 days'
WHERE email_verification_deadline IS NULL AND email_verified = false;

-- For already enabled users (existing accounts), mark them as verified
UPDATE users
SET email_verified = true
WHERE email_verified = false AND enabled = true AND created_at < NOW() - INTERVAL '1 day';

-- Create an index on email_verified for faster queries
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);

-- Create an index on email_verification_deadline for deadline-based queries
CREATE INDEX IF NOT EXISTS idx_users_email_verification_deadline ON users(email_verification_deadline);

-- Verify the migration
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name='users' AND column_name IN ('email_verified', 'email_verification_deadline')
ORDER BY ordinal_position;

