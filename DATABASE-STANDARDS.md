# Database Standards & Best Practices

*Comprehensive guidelines for PostgreSQL and Supabase database development*

**Version:** 1.0  
**Last Updated:** 2025-01-29  
**Purpose:** Single source of truth for database design standards for AI agents and developers

---

## 📋 Table of Contents

1. [Quick Start & Essentials](#1-quick-start--essentials)
2. [Naming Conventions](#2-naming-conventions)
3. [Table Design Standards](#3-table-design-standards)
4. [SQL Function Standards](#4-sql-function-standards)
5. [Supabase-Specific Patterns](#5-supabase-specific-patterns)
6. [Security Best Practices](#6-security-best-practices)
7. [Performance Optimization](#7-performance-optimization)
8. [Migrations & Schema Evolution](#8-migrations--schema-evolution)
9. [Templates & Examples](#9-templates--examples)
10. [Checklist for AI Agent](#10-checklist-for-ai-agent)

---

## 1. Quick Start & Essentials

### Essential Rules

**✅ ALWAYS DO:**
- Use `snake_case` for all database objects
- Include `created_at`, `updated_at` on all tables
- Enable Row Level Security (RLS) on user-facing tables
- Create indexes for foreign keys and frequent queries
- Use UUIDs for main entities, Serial for lookup tables
- Add proper constraints and validation
- Use prefix `p_` for function parameters
- Use prefix `v_` for function local variables
- Always qualify column references with table aliases

**❌ NEVER DO:**
- Use reserved words as table/column names
- Store passwords in plain text
- Create tables without primary keys
- Skip RLS policies on user data
- Use `SELECT *` in production queries
- Ignore migration rollback strategies
- Use parameter names without prefixes (conflicts with columns)
- Write queries without table aliases

### Standard Table Structure

Every table should include:
```sql
-- Primary key
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- or SERIAL for lookup tables

-- Audit fields (required)
created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

-- Optional audit fields
created_by UUID REFERENCES users(id),
updated_by UUID REFERENCES users(id),
deleted_at TIMESTAMP WITH TIME ZONE,  -- for soft deletes
deleted_by UUID REFERENCES users(id)
```

### Standard Function Structure

Every function should:
```sql
CREATE OR REPLACE FUNCTION function_name(
  p_param1 UUID,      -- prefix p_ for parameters
  p_param2 TEXT       -- prefix p_ for parameters
)
RETURNS TABLE (...)
LANGUAGE plpgsql
SECURITY INVOKER      -- Default: runs with caller's permissions
-- SECURITY DEFINER only if absolutely necessary (see Function Security section)
-- SET search_path = public  -- Only needed with SECURITY DEFINER
AS $$
DECLARE
  v_local_var UUID;   -- prefix v_ for local variables
BEGIN
  -- 1. Input validation
  -- 2. Business logic with qualified column references
  -- 3. Return results
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'Error in function_name: %', SQLERRM;
    RAISE EXCEPTION 'Failed: %', SQLERRM;
END;
$$;
```

---

## 2. Naming Conventions

### Quick Reference

| Object Type | Convention | Example | Notes |
|-------------|------------|---------|--------|
| **Tables** | `snake_case` | `user_profiles`, `order_items` | Plural nouns, descriptive |
| **Columns** | `snake_case` | `created_at`, `user_id` | Clear, descriptive |
| **Indexes** | `idx_table_columns` | `idx_users_email`, `idx_orders_customer_date` | Purpose-driven |
| **Functions** | `verb_noun` | `get_user_orders`, `update_user_status` | Action-oriented |
| **Views** | `table_name_v` | `users_summary_v`, `dashboard_stats_v` | Descriptive suffix |
| **Triggers** | `table_action_trigger` | `users_updated_at_trigger` | Clear purpose |
| **Function Parameters** | `p_param_name` | `p_user_id`, `p_team_id` | Prefix `p_` required |
| **Function Variables** | `v_var_name` | `v_request_id`, `v_status` | Prefix `v_` required |

### Tables

**✅ Good Examples:**
```sql
CREATE TABLE user_profiles;          -- Clear, descriptive
CREATE TABLE order_items;            -- Business domain clear
CREATE TABLE product_categories;     -- Descriptive, readable
CREATE TABLE payment_transactions;  -- Clear hierarchy
```

**❌ Bad Examples:**
```sql
CREATE TABLE UserProfiles;    -- PascalCase (avoid)
CREATE TABLE tbl_users;      -- Unnecessary prefix
CREATE TABLE usr;            -- Too abbreviated
CREATE TABLE orderData;      -- camelCase (avoid)
```

### Columns

#### Standard Patterns

**Primary Keys:**
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()    -- Main entities
id SERIAL PRIMARY KEY                            -- Lookup tables
```

**Foreign Keys:**
```sql
user_id         -- References users(id)
order_id        -- References orders(id)  
category_id     -- References categories(id)
parent_id       -- Self-referencing relationship
```

**Timestamps:**
```sql
created_at      -- Creation timestamp
updated_at      -- Last update timestamp
deleted_at      -- Soft delete timestamp
published_at    -- Publication timestamp
expires_at      -- Expiration timestamp
```

**Boolean Fields:**
```sql
is_active       -- Active/inactive state
is_verified     -- Verification status
is_published    -- Publication status
has_permission  -- Permission check
can_edit        -- Capability flag
```

**Status Fields:**
```sql
status          -- General status (enum-like)
state           -- Process state
type            -- Category/classification
priority        -- Priority level
```

**✅ Good Column Examples:**
```sql
first_name              -- Clear personal data
email_address           -- Specific type
phone_number            -- Clear contact info
last_login_at           -- Specific timestamp
total_amount            -- Clear business metric
due_date                -- Clear scheduling
assigned_to             -- Clear relationship
```

**❌ Bad Column Examples:**
```sql
fn                      -- Too abbreviated
dt_created             -- Unclear abbreviation
usr_email              -- Unnecessary prefix
isActive               -- camelCase
user_id_fk             -- Unnecessary suffix
```

### Indexes

**Naming Pattern:** `idx_[table]_[columns]_[purpose]`

**Single Column:**
```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

**Multi-Column (order matters!):**
```sql
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);
CREATE INDEX idx_products_category_price ON products(category_id, price);
CREATE INDEX idx_events_date_type_status ON events(event_date, type, status);
```

**Partial Indexes:**
```sql
CREATE INDEX idx_orders_pending ON orders(created_at) 
WHERE status = 'pending';

CREATE INDEX idx_users_active_email ON users(email)
WHERE is_active = true;
```

**Special Purpose:**
```sql
-- GIN indexes for arrays/JSONB
CREATE INDEX idx_products_tags_gin ON products USING GIN(tags);
CREATE INDEX idx_users_metadata_gin ON users USING GIN(metadata);

-- Expression indexes
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
CREATE INDEX idx_products_name_search ON products USING GIN(to_tsvector('english', name));
```

### Functions & Procedures

**Naming Pattern:** `[verb]_[noun]_[details]`

**✅ Good Examples:**
```sql
-- Action functions
get_user_profile()
update_order_status()
create_audit_log()
calculate_total_price()

-- Validation functions
validate_email_format()
check_user_permissions()
verify_payment_data()

-- Utility functions
generate_slug()
format_currency()
encrypt_data()
```

**❌ Bad Examples:**
```sql
userFunc()              -- Unclear purpose
proc_update()           -- Generic name
getData()               -- Too vague
userStuff()             -- Unprofessional
```

### Views

**Naming Pattern:** `[base_table]_[purpose]_v`

**✅ Good Examples:**
```sql
CREATE VIEW orders_summary_v AS ...;
CREATE VIEW dashboard_metrics_v AS ...;
CREATE VIEW active_users_v AS ...;
CREATE VIEW orders_with_customers_v AS ...;
```

### Triggers

**Naming Pattern:** `[table]_[action]_trigger`

**✅ Good Examples:**
```sql
CREATE TRIGGER users_updated_at_trigger ...;
CREATE TRIGGER orders_audit_trigger ...;
CREATE TRIGGER products_price_validation_trigger ...;
```

### Reserved Words to Avoid

**PostgreSQL Reserved Words:**
```sql
user        -- Use users or user_profiles
order       -- Use orders or customer_orders
group       -- Use groups or user_groups
index       -- Use indexes or search_indexes
table       -- Use tables or data_tables
date        -- Use created_date or event_date
time        -- Use created_time or event_time
count       -- Use record_count or item_count
value       -- Use amount or metric_value
```

---

## 3. Table Design Standards

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

### Data Types & Constraints

#### Recommended Data Types

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

#### Essential Constraints

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

### Indexing Strategy

#### Performance-Critical Indexes

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

#### Covering Indexes

```sql
-- Covering indexes for common queries
CREATE INDEX idx_orders_covering ON orders(customer_id, status) 
INCLUDE (total_amount, created_at);
```

---

## 4. SQL Function Standards

### Critical Rules

**⚠️ CRITICAL:** These rules prevent common errors and ambiguities.

1. **Always use prefixes for parameters and variables**
   - `p_` prefix for function parameters
   - `v_` prefix for local variables
   - Prevents conflicts with column names

2. **Always qualify column references**
   - Use table aliases in all queries
   - Qualify columns with alias: `t.id`, `jr.status`
   - Prevents ambiguous column references

3. **Qualify RETURNING clause columns**
   - Use table name: `join_requests.id`, `join_requests.status`
   - Prevents conflicts with parameters/variables

### Function Naming Conventions

**✅ GOOD PRACTICE:**
```sql
CREATE OR REPLACE FUNCTION public.create_join_request(
  p_team_id UUID,      -- prefix p_ for parameters
  p_user_id UUID       -- prefix p_ for parameters
)
RETURNS TABLE (...)
AS $$
DECLARE
  v_request_id UUID;   -- prefix v_ for local variables
  v_status TEXT;       -- prefix v_ for local variables
BEGIN
  -- function code
END;
$$;
```

**❌ BAD PRACTICE:**
```sql
CREATE OR REPLACE FUNCTION public.create_join_request(
  team_id UUID,        -- CONFLICT with column name!
  user_id UUID         -- CONFLICT with column name!
)
RETURNS TABLE (...)
AS $$
DECLARE
  request_id UUID;     -- CONFLICT with column name!
  status TEXT;         -- CONFLICT with column name!
BEGIN
  -- function code
END;
$$;
```

### Column Qualification in Queries

**✅ GOOD PRACTICE:**
```sql
-- Always use table aliases
SELECT EXISTS(
  SELECT 1 FROM teams t
  WHERE t.id = p_team_id 
    AND t.is_deleted = false
);

-- Explicit aliases in all queries
SELECT EXISTS(
  SELECT 1 FROM join_requests jr
  WHERE jr.team_id = p_team_id 
    AND jr.user_id = p_user_id 
    AND jr.status = 'pending'
);
```

**❌ BAD PRACTICE:**
```sql
-- Without aliases - ambiguous!
SELECT EXISTS(
  SELECT 1 FROM teams
  WHERE id = team_id  -- PostgreSQL doesn't know if this is column or parameter!
);

-- Without qualification - problem with ambiguity
WHERE team_id = team_id  -- Comparing column to itself or to parameter?
```

### RETURNING Clause Qualification

**✅ GOOD PRACTICE:**
```sql
INSERT INTO join_requests (
  id, team_id, user_id, status, created_at
)
VALUES (
  gen_random_uuid(), p_team_id, p_user_id, 'pending', NOW()
)
RETURNING 
  join_requests.id,           -- explicit qualification!
  join_requests.team_id,      -- explicit qualification!
  join_requests.user_id,      -- explicit qualification!
  join_requests.status,       -- explicit qualification!
  join_requests.created_at    -- explicit qualification!
INTO 
  v_request_id, v_team_id, v_user_id, v_status, v_created_at;
```

**❌ BAD PRACTICE:**
```sql
RETURNING 
  id,        -- ambiguous! Is this column or variable?
  team_id,   -- ambiguous!
  user_id,   -- ambiguous!
  status,    -- ambiguous! Conflict with RETURNS TABLE!
  created_at -- ambiguous!
```

### Function Structure Checklist

**Before Writing Function:**
- [ ] Verify exact table structure (read CREATE TABLE statement)
- [ ] Check which columns exist in tables
- [ ] Verify if tables have `created_by`, `updated_at` etc.
- [ ] Read table documentation

**While Writing Function:**
- [ ] Use `p_` prefix for parameters
- [ ] Use `v_` prefix for local variables
- [ ] All SELECT queries must have table aliases
- [ ] All column references must be qualified with alias
- [ ] In RETURNING clause, qualify columns with table name
- [ ] Use direct `IF EXISTS` instead of `SELECT EXISTS ... INTO` where possible

**After Writing Function:**
- [ ] Test function with various inputs
- [ ] Verify all validations work
- [ ] Check error handling
- [ ] Check permissions (GRANT statements)

### Input Validation

**✅ GOOD PRACTICE:**
```sql
BEGIN
  -- Validation at the beginning, clearly separated
  IF p_team_id IS NULL THEN
    RAISE EXCEPTION 'team_id cannot be null' USING ERRCODE = '22000';
  END IF;
  
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id cannot be null' USING ERRCODE = '22000';
  END IF;
  
  -- Then business logic
  IF NOT EXISTS (...) THEN
    ...
  END IF;
END;
```

**Rule:** Input validation at the beginning, then business logic, then return results.

### Error Handling

**✅ GOOD PRACTICE:**
```sql
EXCEPTION
  WHEN OTHERS THEN
    -- Log for debugging
    RAISE LOG 'Error in create_join_request: %', SQLERRM;
    -- User-friendly message
    RAISE EXCEPTION 'Failed to create join request: %', SQLERRM;
```

**Rule:** Always have EXCEPTION block with logging and clear error message.

### Complete Function Example

```sql
CREATE OR REPLACE FUNCTION public.create_join_request(
  p_team_id UUID,
  p_user_id UUID
)
RETURNS TABLE (
  request_id UUID,
  returned_team_id UUID,
  returned_user_id UUID,
  status TEXT,
  created_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY INVOKER  -- Default: uses caller's permissions
-- SET search_path not needed with SECURITY INVOKER
AS $$
DECLARE
  v_request_id UUID;
  v_team_id UUID;
  v_user_id UUID;
  v_status TEXT;
  v_created_at TIMESTAMP;
BEGIN
  -- 1. Input validation
  IF p_team_id IS NULL THEN
    RAISE EXCEPTION 'team_id cannot be null' USING ERRCODE = '22000';
  END IF;
  
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id cannot be null' USING ERRCODE = '22000';
  END IF;
  
  -- 2. Business logic with explicit aliases
  IF NOT EXISTS (
    SELECT 1 FROM teams t
    WHERE t.id = p_team_id AND t.is_deleted = false
  ) THEN
    RAISE EXCEPTION 'team not found or inactive' USING ERRCODE = 'P0001';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM join_requests jr
    WHERE jr.team_id = p_team_id 
      AND jr.user_id = p_user_id 
      AND jr.status = 'pending'
  ) THEN
    RAISE EXCEPTION 'join request already exists and is pending' USING ERRCODE = '23505';
  END IF;
  
  -- 3. INSERT with qualified RETURNING
  INSERT INTO join_requests (
    id, team_id, user_id, status, created_at
  )
  VALUES (
    gen_random_uuid(), p_team_id, p_user_id, 'pending', NOW()
  )
  RETURNING 
    join_requests.id,
    join_requests.team_id,
    join_requests.user_id,
    join_requests.status,
    join_requests.created_at
  INTO 
    v_request_id, v_team_id, v_user_id, v_status, v_created_at;
  
  -- 4. Return result
  RETURN QUERY SELECT 
    v_request_id, v_team_id, v_user_id, v_status, v_created_at;
    
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'Error in create_join_request: %', SQLERRM;
    RAISE EXCEPTION 'Failed to create join request: %', SQLERRM;
END;
$$;
```

### Common Errors Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `column reference "team_id" is ambiguous` | Conflict between parameter and column | Use `p_` prefix for parameters and aliases in queries |
| `column "created_by" does not exist` | Column doesn't exist in table | Check CREATE TABLE before writing function |
| `column reference "status" is ambiguous` | Conflict in RETURNING clause | Qualify columns in RETURNING with table name |
| `column "x" of relation "y" does not exist` | Non-existent column | Verify exact table structure |

---

## 5. Supabase-Specific Patterns

### Row Level Security (RLS)

#### Basic Patterns

**1. User Isolation Pattern:**
```sql
-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Basic user isolation
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);
```

**2. Role-Based Access Pattern:**
```sql
-- Admin access to all records
CREATE POLICY "Admins can view all users" ON user_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Role-based multi-access
CREATE POLICY "Staff can view assigned records" ON orders
  FOR SELECT USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role IN ('admin', 'manager')
    )
  );
```

**3. Ownership with Delegation Pattern:**
```sql
-- Owner or assigned user can access
CREATE POLICY "Owner or assigned can access" ON projects
  FOR ALL USING (
    created_by = auth.uid() OR 
    assigned_to = auth.uid()
  );
```

**4. Time-Based Access Pattern:**
```sql
-- Can only edit recent records
CREATE POLICY "Users can edit recent posts" ON posts
  FOR UPDATE USING (
    user_id = auth.uid() 
    AND created_at > now() - interval '24 hours'
  );

-- Access to active records only
CREATE POLICY "Access to active records" ON subscriptions
  FOR SELECT USING (
    user_id = auth.uid() 
    AND expires_at > now()
  );
```

#### Advanced RLS Patterns

**1. Multi-Tenant Pattern:**
```sql
-- Organization-based isolation
CREATE POLICY "Organization isolation" ON projects
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_organizations uo
      WHERE uo.user_id = auth.uid() 
      AND uo.organization_id = projects.organization_id
    )
  );
```

**2. Hierarchical Access Pattern:**
```sql
-- Manager can see team members' data
CREATE POLICY "Hierarchical access" ON tasks
  FOR SELECT USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN profiles p ON p.user_id = auth.uid()
      WHERE tm.manager_id = p.id 
      AND tm.member_id = tasks.assigned_to
    )
  );
```

**3. Status-Based Access Pattern:**
```sql
-- Different access based on record status
CREATE POLICY "Status-based access" ON documents
  FOR UPDATE USING (
    CASE 
      WHEN status = 'published' THEN 
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
      WHEN status = 'draft' THEN 
        created_by = auth.uid()
      ELSE 
        created_by = auth.uid() OR assigned_to = auth.uid()
    END
  );
```

### Authentication Integration

#### Auto Profile Creation

```sql
-- Function to create profile on user signup
-- NOTE: This trigger function requires SECURITY DEFINER because it's triggered
-- by auth.users table which regular users cannot access. The trigger itself
-- runs in a secure context managed by Supabase.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (
    user_id, 
    email, 
    first_name, 
    last_name,
    role,
    created_at
  ) VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    NEW.created_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

#### Profile Updates

```sql
-- Function to sync profile changes
-- NOTE: This trigger function requires SECURITY DEFINER because it's triggered
-- by auth.users table which regular users cannot access. The trigger itself
-- runs in a secure context managed by Supabase.
CREATE OR REPLACE FUNCTION sync_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Update email if changed
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE profiles 
    SET email = NEW.email, updated_at = now()
    WHERE user_id = NEW.id;
  END IF;
  
  -- Update metadata if changed
  IF NEW.raw_user_meta_data IS DISTINCT FROM OLD.raw_user_meta_data THEN
    UPDATE profiles 
    SET 
      first_name = NEW.raw_user_meta_data->>'first_name',
      last_name = NEW.raw_user_meta_data->>'last_name',
      updated_at = now()
    WHERE user_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION sync_user_profile();
```

#### Helper Functions

```sql
-- Get current user profile
-- NOTE: In Supabase, auth.uid() is accessible to all users, so SECURITY INVOKER works
-- Use SECURITY DEFINER only if you need to bypass RLS or access restricted data
CREATE OR REPLACE FUNCTION get_current_user_profile()
RETURNS profiles AS $$
  SELECT * FROM profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY INVOKER;

-- Check user role
CREATE OR REPLACE FUNCTION has_role(role_name TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = auth.uid() 
    AND role = role_name
  );
$$ LANGUAGE sql SECURITY INVOKER;

-- Get user organization
CREATE OR REPLACE FUNCTION get_user_organization()
RETURNS UUID AS $$
  SELECT organization_id FROM profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY INVOKER;
```

### Realtime Features

#### Basic Table Subscription

```sql
-- Enable realtime for specific tables
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

#### Filtered Realtime

```sql
-- Create view for filtered realtime updates
CREATE VIEW user_notifications_realtime AS
SELECT * FROM notifications 
WHERE user_id = auth.uid();

-- Enable realtime on view
ALTER PUBLICATION supabase_realtime ADD TABLE user_notifications_realtime;
```

#### Dashboard Stats Realtime

```sql
-- Materialized view for dashboard (refresh periodically)
CREATE MATERIALIZED VIEW dashboard_stats AS
SELECT 
  COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE created_at::date = CURRENT_DATE) as today_count,
  SUM(amount) FILTER (WHERE created_at::date = CURRENT_DATE) as today_total
FROM orders;

-- Function to refresh stats
CREATE OR REPLACE FUNCTION refresh_dashboard_stats()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW dashboard_stats;
END;
$$ LANGUAGE plpgsql;

-- Enable realtime (will update when refreshed)
ALTER PUBLICATION supabase_realtime ADD TABLE dashboard_stats;
```

### Storage Patterns

#### File Organization

```sql
-- File uploads table
CREATE TABLE file_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  bucket_name TEXT DEFAULT 'uploads',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for file access
CREATE POLICY "Users can upload files" ON file_uploads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own files" ON file_uploads
  FOR SELECT USING (auth.uid() = user_id);
```

#### Storage Bucket Policies

```sql
-- Bucket policy for user uploads
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Public read access for public files
CREATE POLICY "Public can view public files"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-files');
```

---

## 6. Database Security Best Practices

### Row Level Security (RLS) - Critical Database Protection

**⚠️ CRITICAL: RLS is the primary security mechanism for database access from client applications.**

**RLS Core Principles:**
- **Row Level Security is MANDATORY** - Enable RLS on ALL tables that contain user data (no exceptions)
- RLS policies are evaluated for EVERY database query
- `auth.uid()` is your trusted source of user identity (provided by Supabase Auth)
- Trust ONLY `auth.uid()` for user identification in RLS policies and functions - NEVER accept user IDs from client input

**Database-Level Security Requirements:**
- Enable RLS on ALL tables that contain user data
- Implement ALL validation logic in database functions, not just client-side
- Assume all client input is malicious - validate everything in database functions
- Default to restrictive RLS policies, then open up access as needed

### RLS Implementation Patterns

**When to Use Different RLS Patterns:**

1. **User Isolation** - Use when data belongs to a single user (profiles, private settings)
2. **Role-Based Access** - Use when different user types need different permissions (admin vs user)
3. **Team/Organization Isolation** - Use for multi-tenant applications where users belong to teams
4. **Public/Private Split** - Use when some data is public and some requires authentication
5. **Time-Based Access** - Use when access should expire or have limited windows

### RLS and Views: Critical Misconceptions

**⚠️ CRITICAL MISCONCEPTION: RLS Protects Tables, NOT Views**

Views do NOT have their own RLS protection. When a user queries a view, PostgreSQL scans the underlying base tables where RLS policies MUST exist. Creating a "safe view" with limited columns does NOT protect the data if the base table lacks RLS.

**The Fix:**

Enable RLS on BASE TABLES, not views. Views automatically inherit RLS protection from their base tables.

**Key Rules:**
- RLS policies live on **tables**, not views
- Views inherit RLS from their base tables
- Always enable RLS + policies on base tables BEFORE granting view access

### PostgREST Security: Schema Exposure & RPC Surface

**⚠️ CRITICAL SECURITY RISK: PostgREST automatically exposes your database structure and creates RPC endpoints.**

**Two Critical Exposure Vectors:**

1. **OpenAPI Schema Discovery**: PostgREST exposes an OpenAPI schema revealing all tables, views, and functions the `anon` role can access - including table names, columns, data types, and relationships
2. **Automatic RPC Endpoints**: ALL functions in the `public` schema become callable via HTTP RPC, even internal helpers never intended for client access

**The Problem:**

- Attackers can map your database structure via OpenAPI without accessing data
- Helper functions like `is_admin()`, `check_permissions()`, `count_metrics()` become shadow APIs

### Database Role and Schema Security

**Lock Down the `anon` Role:**
- Start with ZERO grants to `anon`, add only what's absolutely necessary
- Every grant to `anon` becomes a discoverable OpenAPI endpoint
- Prefer minimal views over direct table access for anonymous users

**Separate Public vs Private Schema Functions:**
- Create `app_private` schema for internal helpers, validation, and utility functions
- ONLY put RPC-intended functions in `public` schema
- Use public wrappers with strict validation when RPC access is needed

**Database Schema Organization Checklist:**
- [ ] Move internal helpers to app_private schema
- [ ] Only expose validated, minimal public functions for RPC
- [ ] Use views instead of tables for anonymous access
- [ ] Name public RPC functions clearly (e.g., api_* or rpc_* prefix)
- [ ] Disable OpenAPI for anon if possible

### Service Role Key Security

**Service Role Key Usage:**
- Service role key bypasses ALL RLS policies
- Use ONLY for backend services, migrations, and admin scripts
- NEVER expose in any client-accessible code or configuration

### Authentication & Access Control

#### Role-Based Access Control (RBAC)

```sql
-- Create specific roles for different access levels
CREATE ROLE gym_member;
CREATE ROLE gym_trainer;
CREATE ROLE gym_manager;
CREATE ROLE gym_owner;
CREATE ROLE gym_readonly; -- For reporting/analytics

-- Grant minimal necessary permissions
GRANT SELECT ON members TO gym_trainer;
GRANT SELECT, UPDATE ON member_visits TO gym_trainer;
GRANT INSERT ON member_visits TO gym_trainer;

-- Never grant unnecessary permissions
-- DON'T: GRANT ALL ON ALL TABLES TO gym_trainer;
-- DO: Grant specific permissions only
```

#### Dynamic Permission Checking

```sql
-- Function to verify user permissions before sensitive operations
CREATE OR REPLACE FUNCTION verify_user_permission(
  p_user_id UUID,
  p_permission VARCHAR(100),
  p_resource_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  has_permission BOOLEAN := FALSE;
  user_org_id UUID;
  user_roles TEXT[];
BEGIN
  -- Get user's organization and roles
  SELECT organization_id, ARRAY_AGG(r.name)
  INTO user_org_id, user_roles
  FROM organization_memberships om
  JOIN roles r ON om.role_id = r.id
  WHERE om.user_id = p_user_id 
    AND om.status = 'active'
  GROUP BY organization_id;
  
  -- Check if user has required permission
  SELECT EXISTS (
    SELECT 1 FROM role_permissions rp
    JOIN roles r ON rp.role_id = r.id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE r.name = ANY(user_roles)
      AND p.name = p_permission
      AND rp.granted = true
  ) INTO has_permission;
  
  -- Log permission check for audit
  INSERT INTO security_audit_log (
    user_id, action, resource, permission_checked, granted, ip_address
  ) VALUES (
    p_user_id, 'permission_check', p_resource_id::TEXT, p_permission, has_permission, inet_client_addr()
  );
  
  RETURN has_permission;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
```

### Data Protection & Encryption

#### Column-Level Encryption

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive data
CREATE TABLE encrypted_member_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id),
  
  -- Encrypted fields
  encrypted_ssn BYTEA, -- Social security number
  encrypted_payment_info BYTEA, -- Credit card data
  encrypted_medical_notes BYTEA, -- Health information
  
  -- Encryption metadata
  encryption_key_id VARCHAR(100) NOT NULL,
  encrypted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Function to encrypt sensitive data
-- NOTE: This example uses SECURITY DEFINER because it needs to access
-- encryption keys stored in database settings that regular users shouldn't access.
-- In practice, consider using application-level encryption or a key management service.
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(
  p_data TEXT,
  p_data_type VARCHAR(50)
)
RETURNS BYTEA AS $$
DECLARE
  v_encryption_key TEXT;
BEGIN
  -- Get encryption key based on data type and user permissions
  v_encryption_key := current_setting('app.encryption_key_' || p_data_type);
  
  -- Encrypt the data
  RETURN pgp_sym_encrypt(p_data, v_encryption_key);
EXCEPTION WHEN OTHERS THEN
  -- Log encryption attempt
  INSERT INTO security_audit_log (action, details, error_message)
  VALUES ('encryption_attempt', p_data_type, SQLERRM);
  
  RAISE EXCEPTION 'Encryption failed for data type: %', p_data_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

### Audit Logging

#### Security Audit Table

```sql
CREATE TABLE security_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Who
  user_id UUID REFERENCES auth.users(id),
  session_id UUID,
  impersonated_by UUID REFERENCES auth.users(id), -- If user is being impersonated
  
  -- What
  action VARCHAR(100) NOT NULL, -- 'login', 'data_access', 'permission_change', etc.
  resource_type VARCHAR(100), -- 'member', 'payment', 'staff', etc.
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  
  -- Where
  ip_address INET,
  user_agent TEXT,
  location_country VARCHAR(2),
  location_city VARCHAR(100),
  
  -- Why
  business_justification TEXT,
  
  -- Security context
  risk_score INTEGER DEFAULT 0, -- 0-100
  security_flags TEXT[], -- ['suspicious_location', 'unusual_time', 'bulk_operation']
  
  -- Compliance
  compliance_category VARCHAR(50), -- 'GDPR', 'PCI_DSS', 'HIPAA'
  retention_period INTERVAL DEFAULT INTERVAL '7 years',
  
  -- Metadata
  request_id UUID, -- Trace requests across services
  api_endpoint VARCHAR(255),
  response_status INTEGER,
  processing_time_ms INTEGER,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Indexes for efficient querying
CREATE INDEX idx_security_audit_user_action ON security_audit_log(user_id, action);
CREATE INDEX idx_security_audit_resource ON security_audit_log(resource_type, resource_id);
CREATE INDEX idx_security_audit_created_at ON security_audit_log(created_at);
CREATE INDEX idx_security_audit_risk_score ON security_audit_log(risk_score) WHERE risk_score > 50;
CREATE INDEX idx_security_audit_flags ON security_audit_log USING GIN(security_flags);
```

#### Generic Audit Table

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
-- NOTE: In Supabase, auth.uid() is accessible to all users, so SECURITY INVOKER works.
-- Use SECURITY DEFINER only if you need to audit actions that bypass RLS or
-- if the trigger needs to access data the caller cannot see.
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
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Apply audit trigger to sensitive tables
CREATE TRIGGER audit_users_trigger
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### Security Configuration

#### Function Security

**Default to SECURITY INVOKER** (PostgreSQL's default) - functions run with the caller's permissions.

```sql
-- RECOMMENDED: Use SECURITY INVOKER (default) with GRANT/REVOKE for access control
CREATE OR REPLACE FUNCTION admin_only_function()
RETURNS TABLE(sensitive_data TEXT)
LANGUAGE plpgsql
SECURITY INVOKER  -- Explicit, though this is the default
AS $$
BEGIN
  -- Function logic runs with caller's permissions
  -- PostgreSQL enforces access control via grants
  RETURN QUERY 
    SELECT secret_column::TEXT 
    FROM sensitive_table
    WHERE authorized = true;
END;
$$;

-- Control access using PostgreSQL's built-in security
REVOKE ALL ON FUNCTION admin_only_function() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_only_function() TO admin_role;
GRANT EXECUTE ON FUNCTION admin_only_function() TO manager_role;
```

**SECURITY DEFINER: Use sparingly and with extreme caution**

Only use when you need controlled privilege escalation (e.g., allowing limited access to data the caller can't directly query).

```sql
-- Example: Allow users to check if an email exists without seeing the emails
CREATE OR REPLACE FUNCTION email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- Runs as function owner, not caller
SET search_path = public  -- CRITICAL: Prevent search_path attacks
AS $$
BEGIN
  -- Validate input to prevent SQL injection
  IF p_email IS NULL OR p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format';
  END IF;
  
  -- Function can access users table even if caller cannot
  RETURN EXISTS(SELECT 1 FROM users WHERE email = p_email);
END;
$$;

-- Still control who can execute the function
REVOKE ALL ON FUNCTION email_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION email_exists(TEXT) TO app_user;

-- Set function owner to a role with minimal necessary privileges
ALTER FUNCTION email_exists(TEXT) OWNER TO limited_admin;
```

**Admin access pattern**

```sql
-- Create admin role
CREATE ROLE admin_role;

-- Grant specific privileges
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO admin_role;

-- Create admin function (runs with caller's permissions)
CREATE OR REPLACE FUNCTION get_user_audit_log(p_user_id INT)
RETURNS TABLE(action TEXT, performed_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  -- No manual role checks needed - PostgreSQL handles it
  RETURN QUERY 
    SELECT action_type::TEXT, created_at
    FROM audit_log
    WHERE user_id = p_user_id
    ORDER BY created_at DESC;
END;
$$;

-- Only admins can execute
REVOKE ALL ON FUNCTION get_user_audit_log(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_user_audit_log(INT) TO admin_role;

-- Assign admin role to specific users
GRANT admin_role TO alice;
GRANT admin_role TO bob;
```

#### Input Sanitization

```sql
-- Function to validate and sanitize input
CREATE OR REPLACE FUNCTION sanitize_input(
  p_input_text TEXT,
  p_input_type VARCHAR(50)
)
RETURNS TEXT AS $$
BEGIN
  -- Remove potentially dangerous characters
  p_input_text := regexp_replace(p_input_text, '[<>\"''();]', '', 'g');
  
  CASE p_input_type
    WHEN 'email' THEN
      -- Validate email format
      IF p_input_text !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email format';
      END IF;
      
    WHEN 'phone' THEN
      -- Remove all non-digits and validate length
      p_input_text := regexp_replace(p_input_text, '[^0-9+]', '', 'g');
      IF length(p_input_text) < 10 OR length(p_input_text) > 15 THEN
        RAISE EXCEPTION 'Invalid phone number format';
      END IF;
      
    WHEN 'name' THEN
      -- Only allow letters, spaces, hyphens, apostrophes
      p_input_text := regexp_replace(p_input_text, '[^A-Za-z\s\-'']', '', 'g');
      
  END CASE;
  
  RETURN trim(p_input_text);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## 7. Performance Optimization

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

### Efficient RLS Policies

```sql
-- Optimize RLS with indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_profiles_role ON profiles(role);

-- Efficient policy using indexed columns
CREATE POLICY "Efficient user access" ON orders
  FOR ALL USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );
```

### Monitoring & Maintenance

#### Essential Functions

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

#### Regular Maintenance Tasks

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

## 8. Migrations & Schema Evolution

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

## 9. Templates & Examples

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
CREATE OR REPLACE FUNCTION generate_slug(p_input_text TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN lower(
    regexp_replace(
      regexp_replace(p_input_text, '[^a-zA-Z0-9\s-]', '', 'g'),
      '\s+', '-', 'g'
    )
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## 10. Checklist for AI Agent

### Before Creating a Table

- [ ] Choose appropriate primary key type (UUID for main entities, SERIAL for lookup tables)
- [ ] Plan table name using `snake_case`, plural, descriptive
- [ ] Add `created_at` and `updated_at` timestamps (required)
- [ ] Plan `deleted_at` if soft deletes needed
- [ ] Define all NOT NULL constraints
- [ ] Plan foreign key relationships
- [ ] Plan indexes for foreign keys and frequent queries
- [ ] Consider audit trail requirements (`created_by`, `updated_by`)
- [ ] Check for reserved words in names
- [ ] Plan RLS policies

### After Creating a Table

- [ ] Create necessary indexes (foreign keys, timestamps, status columns)
- [ ] Enable Row Level Security (RLS)
- [ ] Create RLS policies (at least basic user isolation)
- [ ] Add update timestamp trigger
- [ ] Add audit trigger if required
- [ ] Test with sample data
- [ ] Document table purpose and relationships

### Before Creating a Function

- [ ] Read table documentation or CREATE TABLE statements
- [ ] Verify exact table structure (which columns exist)
- [ ] Check if tables have `created_by`, `updated_at` etc.
- [ ] Review similar functions for patterns
- [ ] Plan function name using `verb_noun` pattern

### While Creating a Function

- [ ] Use `p_` prefix for ALL parameters
- [ ] Use `v_` prefix for ALL local variables
- [ ] All SELECT queries MUST have table aliases
- [ ] All column references MUST be qualified with alias (`t.id`, `jr.status`)
- [ ] In RETURNING clause, qualify columns with table name (`join_requests.id`)
- [ ] Input validation at the beginning
- [ ] Business logic in the middle
- [ ] Return results at the end
- [ ] Add EXCEPTION block with logging
- [ ] Default to `SECURITY INVOKER` (PostgreSQL default)
- [ ] Only use `SECURITY DEFINER` in rare cases (see Function Security section) with `SET search_path` and strict input validation

### After Creating a Function

- [ ] Test function with various inputs (valid and invalid)
- [ ] Verify all validations work correctly
- [ ] Check error handling (test error cases)
- [ ] Check permissions (GRANT statements if needed)
- [ ] Verify RLS policies work with function
- [ ] Test with different user roles

### Performance Checklist

- [ ] Monitor slow queries in Supabase dashboard
- [ ] Check index usage with `pg_stat_user_indexes`
- [ ] Monitor table sizes and growth
- [ ] Set up alerts for performance degradation
- [ ] Review and optimize queries regularly
- [ ] Use EXPLAIN ANALYZE for complex queries

### Security Checklist

- [ ] RLS enabled on all user-facing tables
- [ ] RLS policies tested with different user roles
- [ ] Sensitive data encrypted if required
- [ ] Audit logging enabled for sensitive operations
- [ ] Input validation and sanitization in functions
- [ ] Rate limiting considered for public functions
- [ ] Permissions follow principle of least privilege

### Migration Checklist

- [ ] Migration wrapped in transaction (BEGIN/COMMIT)
- [ ] Check if changes already exist before applying
- [ ] Create indexes CONCURRENTLY for large tables
- [ ] Add constraints as NOT VALID first, then validate
- [ ] Test migration on development first
- [ ] Plan rollback strategy
- [ ] Document migration purpose

---

## Quick Reference Commands

### Common Tasks

```sql
-- Create new table with standards
-- (Use template from section 9)

-- Enable RLS on existing table
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Create standard index
CREATE INDEX idx_table_column ON table_name(column_name);

-- Create index concurrently (non-blocking)
CREATE INDEX CONCURRENTLY idx_table_column ON table_name(column_name);

-- Add audit trigger
CREATE TRIGGER table_updated_at
  BEFORE UPDATE ON table_name
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policy
CREATE POLICY "policy_name" ON table_name
  FOR SELECT USING (user_id = auth.uid());
```

### Useful Queries

```sql
-- Check table sizes
SELECT * FROM analyze_table_stats();

-- Find missing indexes on foreign keys
SELECT * FROM pg_stat_user_tables WHERE schemaname = 'public';

-- Review RLS policies
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Check function definitions
SELECT routine_name, routine_definition 
FROM information_schema.routines 
WHERE routine_schema = 'public';
```

---

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Performance Optimization](https://www.postgresql.org/docs/current/performance-tips.html)
- [Supabase Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [PL/pgSQL Documentation](https://www.postgresql.org/docs/current/plpgsql.html)

---

**Remember:** These are guidelines, not rigid rules. Always consider your specific use case and requirements when making architectural decisions. However, the function naming conventions (prefixes `p_` and `v_`) and column qualification rules are **critical** and should always be followed to prevent errors.

---

*Last updated: 2025-01-29 | Version: 1.0 | Consolidated from multiple best practice documents*

