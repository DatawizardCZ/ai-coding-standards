# Database Naming Conventions

*Quick reference for consistent database object naming*

---

## 📋 Quick Reference

| Object Type | Convention | Example | Notes |
|-------------|------------|---------|--------|
| **Tables** | `snake_case` | `user_profiles`, `order_items` | Plural nouns, descriptive |
| **Columns** | `snake_case` | `created_at`, `user_id` | Clear, descriptive |
| **Indexes** | `idx_table_columns` | `idx_users_email`, `idx_orders_customer_date` | Purpose-driven |
| **Functions** | `verb_noun` | `get_user_orders`, `update_user_status` | Action-oriented |
| **Views** | `table_name_v` | `users_summary_v`, `dashboard_stats_v` | Descriptive suffix |
| **Triggers** | `table_action_trigger` | `users_updated_at_trigger` | Clear purpose |

---

## 📚 Tables

### ✅ Good Examples
```sql
CREATE TABLE user_profiles;          -- Clear, descriptive
CREATE TABLE order_items;            -- Business domain clear
CREATE TABLE product_categories;     -- Descriptive, readable
CREATE TABLE payment_transactions;   -- Clear hierarchy
```

### ❌ Bad Examples
```sql
CREATE TABLE UserProfiles;    -- PascalCase (avoid)
CREATE TABLE tbl_users;      -- Unnecessary prefix
CREATE TABLE usr;            -- Too abbreviated
CREATE TABLE orderData;      -- camelCase (avoid)
```

### Common Business Domain Patterns
```sql
-- User Management
users                   -- Main user table
user_profiles          -- Extended user info
user_preferences       -- User settings
user_sessions          -- Session tracking

-- E-commerce
products               -- Product catalog
product_categories     -- Category hierarchy
orders                 -- Customer orders
order_items            -- Order line items
payment_transactions   -- Payment records

-- Content Management  
articles               -- Content pieces
article_categories     -- Content categorization
comments               -- User comments
media_files            -- File uploads

-- SaaS/Subscription
subscriptions          -- User subscriptions
subscription_plans     -- Available plans
usage_metrics          -- Usage tracking
billing_events         -- Billing history
```

---

## 🏷️ Columns

### Standard Patterns

#### Primary Keys
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()    -- Main entities
id SERIAL PRIMARY KEY                            -- Lookup tables
```

#### Foreign Keys
```sql
user_id         -- References users(id)
order_id        -- References orders(id)  
category_id     -- References categories(id)
parent_id       -- Self-referencing relationship
```

#### Timestamps
```sql
created_at      -- Creation timestamp
updated_at      -- Last update timestamp
deleted_at      -- Soft delete timestamp
published_at    -- Publication timestamp
expires_at      -- Expiration timestamp
```

#### Boolean Fields
```sql
is_active       -- Active/inactive state
is_verified     -- Verification status
is_published    -- Publication status
has_permission  -- Permission check
can_edit        -- Capability flag
```

#### Status Fields
```sql
status          -- General status (enum-like)
state           -- Process state
type            -- Category/classification
priority        -- Priority level
```

### ✅ Good Column Examples
```sql
-- Clear and descriptive
first_name              -- Clear personal data
email_address           -- Specific type
phone_number            -- Clear contact info
last_login_at           -- Specific timestamp
total_amount            -- Clear business metric
due_date                -- Clear scheduling
assigned_to             -- Clear relationship
```

### ❌ Bad Column Examples
```sql
-- Unclear or poor naming
fn                      -- Too abbreviated
dt_created             -- Unclear abbreviation
usr_email              -- Unnecessary prefix
isActive               -- camelCase
user_id_fk             -- Unnecessary suffix
```

---

## 🗂️ Indexes

### Naming Pattern
```
idx_[table]_[columns]_[purpose]
```

### Examples by Type

#### Single Column
```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

#### Multi-Column (order matters!)
```sql
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);
CREATE INDEX idx_products_category_price ON products(category_id, price);
CREATE INDEX idx_events_date_type_status ON events(event_date, type, status);
```

#### Partial Indexes
```sql
CREATE INDEX idx_orders_pending ON orders(created_at) 
WHERE status = 'pending';

CREATE INDEX idx_users_active_email ON users(email)
WHERE is_active = true;
```

#### Special Purpose
```sql
-- GIN indexes for arrays/JSONB
CREATE INDEX idx_products_tags_gin ON products USING GIN(tags);
CREATE INDEX idx_users_metadata_gin ON users USING GIN(metadata);

-- Expression indexes
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
CREATE INDEX idx_products_name_search ON products USING GIN(to_tsvector('english', name));
```

---

## ⚙️ Functions & Procedures

### Naming Pattern
```
[verb]_[noun]_[details]
```

### ✅ Good Examples
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

### ❌ Bad Examples
```sql
userFunc()              -- Unclear purpose
proc_update()           -- Generic name
getData()               -- Too vague
userStuff()             -- Unprofessional
```

---

## 👁️ Views

### Naming Pattern
```
[base_table]_[purpose]_v
```

### ✅ Good Examples
```sql
-- Summary views
CREATE VIEW orders_summary_v AS ...;
CREATE VIEW dashboard_metrics_v AS ...;
CREATE VIEW monthly_revenue_v AS ...;

-- Filtered views
CREATE VIEW active_users_v AS ...;
CREATE VIEW pending_orders_v AS ...;

-- Joined views
CREATE VIEW orders_with_customers_v AS ...;
CREATE VIEW products_with_categories_v AS ...;
```

---

## 🔧 Triggers

### Naming Pattern
```
[table]_[action]_trigger
```

### ✅ Good Examples
```sql
-- Audit triggers
CREATE TRIGGER users_updated_at_trigger ...;
CREATE TRIGGER orders_audit_trigger ...;

-- Validation triggers
CREATE TRIGGER products_price_validation_trigger ...;
CREATE TRIGGER users_email_validation_trigger ...;

-- Business logic triggers
CREATE TRIGGER orders_status_change_trigger ...;
CREATE TRIGGER users_welcome_email_trigger ...;
```

---

## 🚫 Reserved Words to Avoid

### PostgreSQL Reserved Words
```sql
-- Never use these as table/column names
user        -- Use users or user_profiles
order       -- Use orders or customer_orders
group       -- Use groups or user_groups
index       -- Use indexes or search_indexes
table       -- Use tables or data_tables
```

### Common Conflicts
```sql
-- Avoid these common issues
date        -- Use created_date or event_date
time        -- Use created_time or event_time
count       -- Use record_count or item_count
value       -- Use amount or metric_value
```

---

## 🎯 Domain-Specific Examples

### E-commerce Platform
```sql
-- Product management
products
product_variants
product_categories
product_images

-- Order processing
orders
order_items
order_status_history
shipping_addresses

-- Customer management
customers
customer_addresses
customer_preferences
customer_reviews
```

### SaaS Application
```sql
-- User management
users
user_profiles
user_sessions
user_preferences

-- Subscription management
subscription_plans
user_subscriptions
billing_cycles
payment_methods

-- Feature management
features
feature_flags
user_feature_access
usage_analytics
```

### Content Management System
```sql
-- Content management
articles
article_categories
article_tags
article_revisions

-- Media management
media_files
media_folders
media_metadata
media_thumbnails

-- User interaction
comments
likes
shares
bookmarks
```

---

## ✅ Validation Checklist

Before committing database changes:

- [ ] All names use `snake_case`
- [ ] Table names are descriptive and plural
- [ ] Column names clearly indicate their purpose
- [ ] Foreign keys end with `_id`
- [ ] Timestamps end with `_at`
- [ ] Booleans start with `is_`, `has_`, `can_`
- [ ] No reserved words used
- [ ] Indexes follow naming pattern
- [ ] Functions use verb_noun pattern

---

## 🔗 Quick Links

- [Best Practices Guide](best-practices.md) - Complete reference
- [Table Template](templates/table-template.sql) - Standard table structure
- [Supabase Patterns](supabase-specific.md) - Platform-specific naming
- [PostgreSQL Reserved Words](https://www.postgresql.org/docs/current/sql-keywords-appendix.html)

---

*Need to add a new naming convention? Update this document and notify the team.*
