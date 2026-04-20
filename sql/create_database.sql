-- Execute with: psql -U postgres -d postgres -f create_database.sql
-- Creates the application database if it does not exist.

SELECT 'CREATE DATABASE visa'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = 'visa'
)\gexec
