-- Initialize CMS Database
-- This script runs when the PostgreSQL container starts for the first time

-- Create additional indexes or configurations if needed
-- The database 'cms_db' is already created via environment variables

-- Grant all privileges to the postgres user (already done by default)
-- GRANT ALL PRIVILEGES ON DATABASE cms_db TO postgres;

-- You can add any initial data or schema setup here
-- For now, we'll let Entity Framework handle the schema creation

-- Set timezone
SET timezone = 'UTC';

-- Log initialization
SELECT 'CMS Database initialized successfully' AS message; 