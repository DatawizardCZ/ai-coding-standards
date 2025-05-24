# PostgreSQL & Supabase Best Practices Guide

*A comprehensive guide for building robust, scalable databases with PostgreSQL and Supabase*

---

## Table of Contents

1. [Database Design Fundamentals](#database-design-fundamentals)
2. [Naming Conventions](#naming-conventions)
3. [Data Types & Constraints](#data-types--constraints)
4. [Indexing Strategy](#indexing-strategy)
5. [Supabase-Specific Practices](#supabase-specific-practices)
6. [Security & Access Control](#security--access-control)
7. [Performance Optimization](#performance-optimization)
8. [Schema Evolution & Migrations](#schema-evolution--migrations)
9. [Monitoring & Maintenance](#monitoring--maintenance)
10. [Code Examples & Templates](#code-examples--templates)

---

## Database Design Fundamentals

### Table Structure Guidelines

**✅ DO:**
- Use consistent naming patterns across all tables
- Include audit fields (`created_at`, `updated_at`) on all tables
- Design for data integrity with proper foreign keys
- Plan for soft deletes with `deleted_at` fields
- Use appropriate data types for each field

**❌ DON'T:**
- Create tables without primary keys
- Use reserved words as table/column names
- Store JSON when relational data is more appropriate
- Ignore normalization principles
- Create circular foreign key dependencies

### Primary Key Strategy

```sql
-- Main business entities: Use UUIDs for distributed systems
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Reference/lookup tables: Use serial integers for efficiency
CREATE TABLE user_roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT
);
```

---

## Naming Conventions

### Tables
```sql
-- Use snake_case, descriptive names
CREATE TABLE user_profiles;        -- ✅ Good
CREATE TABLE customer_orders;      -- ✅ Good
CREATE TABLE UserProfiles;         -- ❌ Avoid PascalCase
CREATE TABLE tbl_users;           -- ❌ Avoid prefixes
```

### Columns
```sql
-- Use descriptive snake_case names
user_id                 -- ✅ Clear foreign key
created_at             -- ✅ Standard timestamp
is_active              -- ✅ Boolean prefix
total_amount           -- ✅ Descriptive
status_id              -- ✅ Foreign key pattern

-- Avoid unclear abbreviations
usr_id                 -- ❌ Unclear
dt_created             -- ❌ Unclear abbreviation
```

### Indexes
```sql
-- Pattern: idx_tablename_columns_purpose
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, created_at);
CREATE INDEX idx_products_active_category ON products(is_active, category_id);
```

### Functions & Procedures
```sql
-- Use verb_noun pattern
CREATE FUNCTION get_user_orders();
CREATE FUNCTION update_user_status();
CREATE FUNCTION calculate_monthly_revenue();
```

---

## Data Types & Constraints

### Recommended Data Types

```sql
-- Text Fields
email VARCHAR(255)              -- Fixed max length
description TEXT                -- Variable length
status VARCHAR(20)              -- Enum-like values
code VARCHAR(10)                -- Short codes

-- Numbers
user_id BIGSERIAL              -- Auto-incrementing IDs
price DECIMAL(10,2)            -- Money (avoid FLOAT)
quantity INTEGER               -- Whole numbers
percentage DECIMAL(5,2)        -- Percentages (0.00-100.00)

-- Dates & Times
created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
scheduled_date DATE
duration_minutes INTEGER

-- Boolean
is_active BOOLEAN DEFAULT true
has_paid BOOLEAN DEFAULT false

-- Arrays & JSON
tags TEXT[]                    -- Simple arrays
metadata JSONB                 -- Complex structured data
```

### Essential Constraints

```sql
-- NOT NULL for required fields
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- CHECK constraints for data validation
ALTER TABLE users ADD CONSTRAINT check_email_format 
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

ALTER TABLE products ADD CONSTRAINT check_price_positive 
  CHECK (price > 0);

ALTER TABLE orders ADD CONSTRAINT check_status_values 
  CHECK (status IN ('pending', 'processing', 'completed', 'cancelled'));

-- UNIQUE constraints
ALTER TABLE users ADD CONSTRAINT unique_users_email UNIQUE (email);
ALTER TABLE products ADD CONSTRAINT unique_products_sku UNIQUE (sku);

-- Foreign key constraints with proper naming
ALTER TABLE orders ADD CONSTRAINT fk_orders_customer_id 
  FOREIGN KEY (customer_id) REFERENCES customers(id);
```

---

## Indexing Strategy

### Basic Index Types

```sql
-- Single column indexes (most common)
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_status ON orders(status);

-- Composite indexes (order matters!)
CREATE INDEX idx_orders_customer_date ON orders(customer_id, created_at);
CREATE INDEX idx_products_category_price ON products(category_id, price);

-- Partial indexes (for filtered queries)
CREATE INDEX idx_orders_pending ON orders(created_at) 
WHERE status = 'pending';

-- GIN indexes (for arrays, JSONB, full-text search)
CREATE INDEX idx_products_tags ON products USING GIN(tags);
CREATE INDEX idx_users_metadata ON users USING GIN(metadata);

-- Expression indexes
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

### Performance-Critical Indexes

```sql
-- Foreign key columns (for joins)
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- Timestamp columns (for date ranges)
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_users_last_login ON users(last_login_at);

-- Status/enum columns (for filtering)
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Combination indexes for common query patterns
CREATE INDEX idx_orders_customer_status_date ON orders(customer_id, status, created_at);
```

---

## Supabase-Specific Practices

### Row Level Security (RLS)

```sql
-- Enable RLS on all user-facing tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Basic user isolation policy
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Role-based access policy
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Time-based access policy
CREATE POLICY "Users can edit recent posts" ON posts
  FOR UPDATE USING (
    user_id = auth.uid() 
    AND created_at > now() - interval '24 hours'
  );
```

### Authentication Integration

```sql
-- Profile creation trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (user_id, email, created_at)
  VALUES (NEW.id, NEW.email, NEW.created_at);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Realtime Subscriptions

```sql
-- Enable realtime for specific tables
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Create a view for realtime dashboard data
CREATE VIEW dashboard_stats AS
SELECT 
  COUNT(*) FILTER (WHERE status = 'pending') as pending_orders,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
  SUM(total_amount) FILTER (WHERE created_at::date = CURRENT_DATE) as today_revenue
FROM orders;

ALTER PUBLICATION supabase_realtime ADD TABLE dashboard_stats;
```

---

## Security & Access Control

### Data Protection

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Encrypt sensitive data
CREATE TABLE user_secrets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  encrypted_data BYTEA NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Function to encrypt data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT)
RETURNS BYTEA AS $$
BEGIN
  RETURN pgp_sym_encrypt(data, current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Audit Logging

```sql
-- Generic audit table
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  old_values JSONB,
  new_values JSONB,
  user_id UUID,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ip_address INET,
  user_agent TEXT
);

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (
    table_name, record_id, operation, old_values, new_values, user_id
  ) VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) END,
    auth.uid()
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit trigger to sensitive tables
CREATE TRIGGER audit_users_trigger
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

---

## Performance Optimization

### Query Optimization

```sql
-- Use EXPLAIN ANALYZE to understand query performance
EXPLAIN ANALYZE 
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.customer_id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.name;

-- Create covering indexes for common queries
CREATE INDEX idx_orders_covering ON orders(customer_id, status) 
INCLUDE (total_amount, created_at);
```

### Materialized Views

```sql
-- Create materialized view for expensive aggregations
CREATE MATERIALIZED VIEW monthly_revenue_mv AS
SELECT 
  DATE_TRUNC('month', created_at) as month,
  SUM(total_amount) as revenue,
  COUNT(*) as order_count,
  AVG(total_amount) as avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', created_at);

-- Index the materialized view
CREATE INDEX idx_monthly_revenue_month ON monthly_revenue_mv(month);

-- Refresh strategy (can be automated)
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue_mv;
```

### Partitioning (for large tables)

```sql
-- Time-based partitioning for large tables
CREATE TABLE orders_partitioned (
  id UUID DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL,
  total_amount DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE orders_2024_01 PARTITION OF orders_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders_partitioned
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

---

## Schema Evolution & Migrations

### Migration Best Practices

```sql
-- Migration template
-- migration_YYYY_MM_DD_description.sql

BEGIN;

-- Always check if changes already exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'users' AND column_name = 'phone') THEN
    ALTER TABLE users ADD COLUMN phone VARCHAR(20);
  END IF;
END $$;

-- Create indexes concurrently (non-blocking)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_phone ON users(phone);

-- Add constraints safely
ALTER TABLE users ADD CONSTRAINT check_phone_format 
  CHECK (phone ~ '^\+?[1-9]\d{1,14}$');

COMMIT;
```

### Backward Compatibility

```sql
-- Safe column addition (always nullable initially)
ALTER TABLE users ADD COLUMN middle_name VARCHAR(50);

-- Safe constraint addition (validate existing data first)
-- Step 1: Add constraint as NOT VALID
ALTER TABLE users ADD CONSTRAINT check_email_domain 
  CHECK (email LIKE '%@company.com') NOT VALID;

-- Step 2: Validate existing data
ALTER TABLE users VALIDATE CONSTRAINT check_email_domain;

-- Safe column removal (use views for transition period)
-- Step 1: Create view without deprecated column
CREATE VIEW users_v2 AS 
SELECT id, email, name, created_at FROM users;

-- Step 2: Update application to use view
-- Step 3: After transition, drop column
-- ALTER TABLE users DROP COLUMN deprecated_field;
```

---

## Monitoring & Maintenance

### Essential Functions

```sql
-- Function to analyze table statistics
CREATE OR REPLACE FUNCTION analyze_table_stats()
RETURNS TABLE(
  table_name TEXT,
  row_count BIGINT,
  table_size TEXT,
  index_size TEXT,
  total_size TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    schemaname || '.' || tablename as table_name,
    n_tup_ins + n_tup_upd + n_tup_del as row_count,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as index_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) + 
                   pg_indexes_size(schemaname||'.'||tablename)) as total_size
  FROM pg_stat_user_tables
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;
```

### Regular Maintenance Tasks

```sql
-- Auto-vacuum configuration
ALTER TABLE large_table SET (
  autovacuum_vacuum_scale_factor = 0.1,
  autovacuum_analyze_scale_factor = 0.05
);

-- Update table statistics
ANALYZE users;
ANALYZE orders;

-- Reindex (if needed)
REINDEX INDEX CONCURRENTLY idx_users_email;
```

---

## Code Examples & Templates

### Standard Table Template

```sql
-- Standard table template with all best practices
CREATE TABLE template_table (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Business fields
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'active' 
    CHECK (status IN ('active', 'inactive', 'archived')),
  
  -- Foreign keys
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(id),
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  
  -- Audit fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  
  -- Soft delete
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES users(id)
);

-- Standard indexes
CREATE INDEX idx_template_table_user_id ON template_table(user_id);
CREATE INDEX idx_template_table_status ON template_table(status);
CREATE INDEX idx_template_table_created_at ON template_table(created_at);
CREATE INDEX idx_template_table_tags ON template_table USING GIN(tags);

-- Enable RLS
ALTER TABLE template_table ENABLE ROW LEVEL SECURITY;

-- Basic RLS policy
CREATE POLICY "Users can access own records" ON template_table
  FOR ALL USING (user_id = auth.uid());

-- Updated timestamp trigger
CREATE TRIGGER template_table_updated_at
  BEFORE UPDATE ON template_table
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit trigger
CREATE TRIGGER template_table_audit
  AFTER INSERT OR UPDATE OR DELETE ON template_table
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### Common Utility Functions

```sql
-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Soft delete function
CREATE OR REPLACE FUNCTION soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE template_table 
    SET deleted_at = now(), deleted_by = auth.uid()
    WHERE id = OLD.id;
    RETURN NULL; -- Prevent actual delete
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Generate slug function
CREATE OR REPLACE FUNCTION generate_slug(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN lower(
    regexp_replace(
      regexp_replace(input_text, '[^a-zA-Z0-9\s-]', '', 'g'),
      '\s+', '-', 'g'
    )
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## Quick Reference Checklist

### Before Creating a New Table
- [ ] Choose appropriate primary key type (UUID vs Serial)
- [ ] Add `created_at` and `updated_at` timestamps
- [ ] Define all NOT NULL constraints
- [ ] Plan foreign key relationships
- [ ] Consider soft delete requirements
- [ ] Plan for audit trail if needed

### After Creating a Table
- [ ] Create necessary indexes
- [ ] Enable Row Level Security
- [ ] Create RLS policies
- [ ] Add update timestamp trigger
- [ ] Add audit trigger if required
- [ ] Test with sample data
- [ ] Document purpose and relationships

### Performance Monitoring
- [ ] Monitor slow queries in Supabase dashboard
- [ ] Check index usage with `pg_stat_user_indexes`
- [ ] Monitor table sizes and growth
- [ ] Set up alerts for performance degradation
- [ ] Review and optimize queries regularly

---

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Performance Optimization](https://www.postgresql.org/docs/current/performance-tips.html)
- [Supabase Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

*Remember: These are guidelines, not rigid rules. Always consider your specific use case and requirements when making architectural decisions.*
