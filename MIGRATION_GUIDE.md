# Database Migration Guide - Email Verification Fields

## Issue
The application is trying to query `email_verified` and `email_verification_deadline` columns that don't exist in the database yet, causing SQL errors:

```
ERROR: column u1_0.email_verified does not exist
ERROR: column u1_0.email_verification_deadline does not exist
```

## Solution
You need to run the migration script to add these columns to the PostgreSQL `users` table.

## How to Apply the Migration

### Option 1: Using PgAdmin (Recommended for GUI users)
1. Open PgAdmin
2. Navigate to the `techtorque` database
3. Open the Query Editor
4. Copy and paste the SQL from `Database/migrations/001_add_email_verification_fields.sql`
5. Click "Execute" button
6. Verify the operation completed successfully

### Option 2: Using psql Command Line
```bash
# Connect to the database
psql -h localhost -U techtorque -d techtorque -f "Database/migrations/001_add_email_verification_fields.sql"

# When prompted, enter password: techtorque123
```

### Option 3: Using Docker (if PostgreSQL is in Docker)
```bash
# Copy the migration file to the container and execute
docker exec -i postgres_container psql -U techtorque -d techtorque < Database/migrations/001_add_email_verification_fields.sql
```

## Migration Details

The migration script performs the following operations:

### 1. Add `email_verified` Column
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;
```
- Type: BOOLEAN (true/false)
- Default: false (new users start as unverified)
- Not Null: Required field

### 2. Add `email_verification_deadline` Column
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_deadline TIMESTAMP;
```
- Type: TIMESTAMP (stores date and time)
- Default: NULL (set dynamically on registration)
- Can be NULL: For already verified users

### 3. Initialize Existing Users
```sql
UPDATE users 
SET email_verification_deadline = NOW() + INTERVAL '7 days'
WHERE email_verification_deadline IS NULL AND email_verified = false;
```
- Sets 7-day deadline for any existing unverified users
- Existing users who are already enabled are marked as verified

### 4. Create Performance Indexes
```sql
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);
CREATE INDEX IF NOT EXISTS idx_users_email_verification_deadline ON users(email_verification_deadline);
```
- Improves query performance when filtering by verification status
- Helps with deadline-based queries

## Verifying the Migration

After running the migration, verify the columns exist:

### Option 1: Using PgAdmin
1. Go to Database → techtorque → Schemas → public → Tables → users
2. Right-click and select "Properties"
3. Look for `email_verified` and `email_verification_deadline` columns

### Option 2: Using SQL Query
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name='users' 
ORDER BY ordinal_position;
```

You should see output similar to:
```
column_name                      | data_type | is_nullable
---------------------------------|-----------|-----------
id                               | bigint    | NO
username                         | varchar   | NO
email                            | varchar   | NO
password                          | varchar   | NO
enabled                          | boolean   | NO
created_at                       | timestamp | NO
email_verified                   | boolean   | NO
email_verification_deadline      | timestamp | YES
...
```

## What to Do After Migration

1. **Restart the Authentication Service**
   ```bash
   # If using Maven
   mvn spring-boot:run
   
   # If using Docker
   docker-compose restart auth-service
   ```

2. **Test the Login Flow**
   - Register a new user
   - Verify you can log in immediately
   - Check profile page for verification status
   - Test resend verification email button

3. **Verify Email Link**
   - Check your email for verification link
   - Click the link to verify email
   - Confirm profile updates to "Email Verified ✓"

## Rollback (If Needed)

If you need to revert the migration:

```sql
-- Drop the indexes
DROP INDEX IF EXISTS idx_users_email_verified;
DROP INDEX IF EXISTS idx_users_email_verification_deadline;

-- Drop the columns
ALTER TABLE users DROP COLUMN IF EXISTS email_verified;
ALTER TABLE users DROP COLUMN IF EXISTS email_verification_deadline;
```

## Database Schema Update

The `users` table now has the following relevant columns:

| Column Name | Type | Nullable | Default | Purpose |
|---|---|---|---|---|
| id | BIGINT | NO | SERIAL | Primary key |
| username | VARCHAR | NO | | User login name |
| email | VARCHAR | NO | | User email address |
| password | VARCHAR | NO | | Encrypted password |
| enabled | BOOLEAN | NO | true | Account active status |
| email_verified | BOOLEAN | NO | false | Email verification status |
| email_verification_deadline | TIMESTAMP | YES | NULL | 7-day verification deadline |
| created_at | TIMESTAMP | NO | NOW() | Account creation date |

## Troubleshooting

### Error: "column already exists"
This is normal if you've already run the migration. The `IF NOT EXISTS` clause prevents errors on re-runs.

### Error: "syntax error"
Ensure you're using PostgreSQL syntax, not MySQL. The migration uses PostgreSQL-specific features like:
- `IF NOT EXISTS`
- `INTERVAL` for date math
- `information_schema` for verification

### Still getting "column does not exist" errors after migration
1. Verify the migration ran successfully
2. Restart the application service
3. Clear any database connection pools/caches
4. Restart the entire application

## Migration Rollout Strategy

### For Development
- Apply immediately and test thoroughly

### For Staging
- Apply migration first
- Restart services
- Run full integration tests
- Verify user workflows

### For Production
1. **Backup Database** - Create a backup before migration
2. **Schedule Downtime** - Plan during low-traffic period
3. **Apply Migration** - Run the SQL script
4. **Restart Services** - Restart all authentication services
5. **Monitor** - Watch logs for errors
6. **Test** - Verify registration and login flows
7. **Communicate** - Notify users if needed

## Support

If you encounter issues:
1. Check application logs for exact SQL error
2. Verify PostgreSQL version (9.6+)
3. Ensure user has ALTER TABLE permissions
4. Verify column naming matches application code
5. Check database connectivity and credentials

