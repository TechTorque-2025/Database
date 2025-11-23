-- Migration for BLOB-based profile photo storage
-- This adds binary photo storage and caching support to user profiles

-- Add columns to users table for binary profile photo storage
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo BYTEA;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_updated_at TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_mime_type VARCHAR(50);

-- Create index for faster photo lookups
CREATE INDEX IF NOT EXISTS idx_users_profile_photo_updated_at ON users(profile_photo_updated_at);

-- Add comment for documentation
COMMENT ON COLUMN users.profile_photo IS 'Binary profile photo data (BLOB) - stored as BYTEA in PostgreSQL';
COMMENT ON COLUMN users.profile_photo_updated_at IS 'Timestamp when profile photo was last updated - used for cache validation';
COMMENT ON COLUMN users.profile_photo_mime_type IS 'MIME type of profile photo (e.g., image/jpeg, image/png)';

