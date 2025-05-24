# Database Standards & Best Practices

*Comprehensive guidelines for PostgreSQL and Supabase development*

---

## 🚀 Quick Start

**New to our database standards?** Start here:

1. 📖 Read [Naming Conventions](naming-conventions.md) - *5 min read*
2. 🛠️ Use [Table Template](templates/table-template.sql) for new tables
3. ✅ Follow [New Table Checklist](checklists/new-table.md) before committing
4. 🔍 Review [Supabase Patterns](supabase-specific.md) for platform-specific practices

---

## 📚 Documentation Structure

### Core Guidelines
| Document | Purpose | When to Use |
|----------|---------|-------------|
| [**Best Practices**](best-practices.md) | Complete reference guide | Designing new schemas, optimizing performance |
| [**Naming Conventions**](naming-conventions.md) | Quick naming reference | Every table, column, index creation |
| [**Supabase Specific**](supabase-specific.md) | Platform-specific patterns | RLS, auth integration, realtime features |

### Templates & Tools
| Resource | Purpose | When to Use |
|----------|---------|-------------|
| [Table Template](templates/table-template.sql) | Standard table structure | Creating any new table |
| [Migration Template](templates/migration-template.sql) | Safe schema changes | Database updates |
| [Function Template](templates/function-template.sql) | Common function patterns | Custom database functions |

### Checklists
| Checklist | Purpose | When to Use |
|-----------|---------|-------------|
| [New Table](checklists/new-table.md) | Pre/post table creation | Before committing new tables |
| [Migration](checklists/migration.md) | Safe migration practices | Before deploying schema changes |
| [Performance Review](checklists/performance-review.md) | Optimization checklist | Performance issues |

---

## 🎯 Our Standards at a Glance

### ✅ Always Do
- Use `snake_case` for all database objects
- Include `created_at`, `updated_at` on all tables
- Enable Row Level Security (RLS) on user-facing tables
- Create indexes for foreign keys and frequent queries
- Use UUIDs for main entities, Serial for lookup tables
- Add proper constraints and validation

### ❌ Never Do
- Use reserved words as table/column names
- Store passwords in plain text
- Create tables without primary keys
- Skip RLS policies on user data
- Use `SELECT *` in production queries
- Ignore migration rollback strategies

---

## 🔧 Quick Reference Commands

### Common Tasks
```sql
-- Create new table with our standards
\i templates/table-template.sql

-- Enable RLS on existing table
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Create standard index
CREATE INDEX idx_table_column ON table_name(column_name);

-- Add audit trigger
CREATE TRIGGER table_updated_at
  BEFORE UPDATE ON table_name
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Useful Queries
```sql
-- Check table sizes
SELECT * FROM analyze_table_stats();

-- Find missing indexes on foreign keys
SELECT * FROM pg_stat_user_tables WHERE schemaname = 'public';

-- Review RLS policies
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

---

## 🏗️ Project Customization

Adapt these standards to your project by:

1. **Define domain prefixes** for your business logic
2. **Set required fields** for your use case
3. **Create project-specific RLS patterns**
4. **Add business-specific validation rules**

### Example Project Adaptations

**E-commerce Platform:**
```sql
-- Table prefixes
product_*        -- Product management
order_*          -- Order processing  
customer_*       -- Customer data
inventory_*      -- Stock management
```

**SaaS Application:**
```sql
-- Table prefixes
user_*          -- User management
subscription_*  -- Billing & subscriptions
feature_*       -- Feature flags
usage_*         -- Usage tracking
```

**Content Management:**
```sql
-- Table prefixes
content_*       -- Content management
media_*         -- Media files
workflow_*      -- Approval workflows
publication_*   -- Publishing system
```

---

## 🚨 Common Pitfalls & Solutions

| Problem | Solution | Reference |
|---------|----------|-----------|
| Slow queries | Missing indexes | [Performance Guide](best-practices.md#performance-optimization) |
| RLS denying access | Check policy conditions | [Supabase RLS](supabase-specific.md#row-level-security) |
| Migration failures | Use transaction blocks | [Migration Template](templates/migration-template.sql) |
| Data integrity issues | Add proper constraints | [Best Practices](best-practices.md#data-types--constraints) |

---

## 🔄 Workflow Integration

### Before Creating Tables
1. Review [naming conventions](naming-conventions.md)
2. Copy [table template](templates/table-template.sql)
3. Plan indexes and constraints
4. Design RLS policies

### After Creating Tables
1. Run [new table checklist](checklists/new-table.md)
2. Test with sample data
3. Verify RLS policies work
4. Update documentation

### For Migrations
1. Use [migration template](templates/migration-template.sql)
2. Test on development first
3. Run [migration checklist](checklists/migration.md)
4. Monitor performance post-deploy

---

## 🤝 Contributing

Found an issue or have a suggestion? 

1. **Quick fixes**: Update the relevant document directly
2. **New patterns**: Add to [best-practices.md](best-practices.md)  
3. **Templates**: Add to `templates/` folder
4. **Project-specific**: Update your project's README

---

## 📞 Support

**Need help?**
- 📖 Check [Best Practices Guide](best-practices.md) first
- 🔍 Search existing documentation
- 💬 Ask in team chat with `#database` tag
- 📝 Create issue with `database` label

---

## 📋 Related Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [Database Design Principles](https://en.wikipedia.org/wiki/Database_design)
- [SQL Style Guide](https://www.sqlstyle.guide/)

---

*Last updated: [DATE] | Version: 1.0*
