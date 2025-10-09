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