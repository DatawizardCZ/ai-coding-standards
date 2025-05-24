# New Table Checklist

*Complete this checklist before committing any new table to production*

---

## 📋 Pre-Creation Planning

### ✅ Table Design
- [ ] **Table name** follows `snake_case` convention and is descriptive
- [ ] **Primary key strategy** decided (UUID for main entities, Serial for lookups)
- [ ] **Business requirements** clearly defined and documented
- [ ] **Data relationships** mapped out (foreign keys, references)
- [ ] **Expected data volume** estimated for performance planning
- [ ] **Access patterns** identified (who reads/writes, how often)

### ✅ Column Planning
- [ ] **Required fields** identified and marked as NOT NULL
- [ ] **Optional fields** designed as nullable
- [ ] **Data types** chosen appropriately (no over-sized types)
- [ ] **Constraints** planned (CHECK, UNIQUE, foreign keys)
- [ ] **Default values** defined where appropriate
- [ ] **Enum-like fields** validated with CHECK constraints

### ✅ Security Planning
- [ ] **User access patterns** defined (who can see what)
- [ ] **RLS policies** designed for different user roles
- [ ] **Sensitive data** identified and protection planned
- [ ] **Audit requirements** considered (tracking changes)

---

## 🛠️ During Creation

### ✅ Table Structure
- [ ] **Primary key** created with appropriate type
- [ ] **Created/updated timestamps** added (`created_at`, `updated_at`)
- [ ] **Audit fields** added if needed (`created_by`, `updated_by`)
- [ ] **Soft delete support** added if needed (`deleted_at`, `deleted_by`)
- [ ] **Foreign key constraints** created with proper references
- [ ] **Check constraints** added for data validation
- [ ] **Default values** set appropriately

### ✅ Comments and Documentation
- [ ] **Table comment** added explaining purpose
- [ ] **Column comments** added for complex or business-specific fields
- [ ] **Constraint documentation** added for business rules

```sql
-- Example documentation
COMMENT ON TABLE orders IS 'Customer orders with payment and fulfillment tracking';
COMMENT ON COLUMN orders.status IS 'Order status: pending, processing, shipped, delivered, cancelled';
```

---

## 🗂️ Post-Creation Setup

### ✅ Indexes (CRITICAL for performance)
- [ ] **Foreign key indexes** created for ALL foreign keys
- [ ] **Status/enum indexes** created for filtering columns
- [ ] **Timestamp indexes** created for date range queries
- [ ] **Composite indexes** created for common query patterns
- [ ] **Partial indexes** created for frequently filtered subsets
- [ ] **GIN indexes** created for JSONB/array columns if needed

```sql
-- Essential indexes checklist
CREATE INDEX idx_table_user_id ON table_name(user_id);           -- Foreign keys
CREATE INDEX idx_table_status ON table_name(status);             -- Status columns
CREATE INDEX idx_table_created_at ON table_name(created_at);     -- Timestamps
CREATE INDEX idx_table_user_status ON table_name(user_id, status); -- Composite
```

### ✅ Row Level Security (RLS)
- [ ] **RLS enabled** on the table
- [ ] **SELECT policy** created for data access
- [ ] **INSERT policy** created with proper validation
- [ ] **UPDATE policy** created with ownership checks
- [ ] **DELETE policy** created with proper restrictions
- [ ] **Admin policies** created if needed for elevated access

```sql
-- Basic RLS setup
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_data" ON table_name FOR ALL USING (user_id = auth.uid());
```

### ✅ Triggers and Functions
- [ ] **Update timestamp trigger** created and applied
- [ ] **Audit trigger** created if tracking changes
- [ ] **Validation trigger** created if complex business rules
- [ ] **Soft delete trigger** created if using soft deletes

```sql
-- Standard trigger setup
CREATE TRIGGER table_name_updated_at
  BEFORE UPDATE ON table_name
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 🧪 Testing and Validation

### ✅ Data Integrity Testing
- [ ] **Insert test data** to verify constraints work
- [ ] **Foreign key constraints** tested (valid and invalid references)
- [ ] **Check constraints** tested with boundary values
- [ ] **Default values** verified for new records
- [ ] **NULL handling** tested for optional fields

### ✅ RLS Policy Testing
- [ ] **User isolation** tested (users see only their data)
- [ ] **Admin access** tested (admins see all data if intended)
- [ ] **Cross-user access** tested (should be denied)
- [ ] **Role-based access** tested with different user roles
- [ ] **Edge cases** tested (missing relationships, null values)

### ✅ Performance Testing
- [ ] **Index usage** verified with EXPLAIN ANALYZE
- [ ] **Query performance** tested with realistic data volume
- [ ] **RLS policy performance** measured and optimized
- [ ] **Foreign key performance** tested for joins

```sql
-- Performance testing examples
EXPLAIN ANALYZE SELECT * FROM table_name WHERE user_id = 'test-uuid';
EXPLAIN ANALYZE SELECT * FROM table_name WHERE status = 'active';
```

---

## 📱 Application Integration

### ✅ Backend Integration
- [ ] **TypeScript types** generated/updated for the new table
- [ ] **API endpoints** created if needed
- [ ] **Validation schemas** created for input validation
- [ ] **Business logic** implemented for CRUD operations
- [ ] **Error handling** implemented for constraint violations

### ✅ Frontend Integration
- [ ] **UI components** updated to handle new data
- [ ] **Forms** created for data input if needed
- [ ] **Validation** implemented on client-side
- [ ] **Error messages** user-friendly and helpful

---

## 📊 Monitoring and Maintenance

### ✅ Realtime Setup (if needed)
- [ ] **Realtime publication** enabled for live updates
- [ ] **Client subscriptions** tested and working
- [ ] **Performance impact** of realtime measured

```sql
-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE table_name;
```

### ✅ Monitoring Setup
- [ ] **Query performance** baseline established
- [ ] **Table size monitoring** set up
- [ ] **Error logging** configured for constraint violations
- [ ] **Usage patterns** documented for future optimization

---

## 📝 Documentation

### ✅ Technical Documentation
- [ ] **Database schema** documentation updated
- [ ] **API documentation** updated with new endpoints
- [ ] **ERD diagrams** updated to show new relationships
- [ ] **Migration scripts** documented and version controlled
- [ ] **Rollback procedures** documented

### ✅ Team Communication
- [ ] **Team notified** of new table and its purpose
- [ ] **Breaking changes** communicated if any
- [ ] **Usage examples** provided for other developers
- [ ] **Code review** completed by senior team member

---

## 🚨 Common Gotchas to Avoid

### ❌ Schema Issues
- [ ] **Verify no reserved words** used as table/column names
- [ ] **Check column sizes** aren't unnecessarily large (VARCHAR(1000) vs VARCHAR(100))
- [ ] **Avoid premature optimization** (don't over-index initially)
- [ ] **Foreign key naming** follows convention (`table_id` not `tableId`)

### ❌ Security Issues
- [ ] **RLS enabled** - never skip this for user-facing tables
- [ ] **Policies tested** with actual user scenarios
- [ ] **Admin policies** don't accidentally grant too much access
- [ ] **Sensitive data** properly protected

### ❌ Performance Issues
- [ ] **Foreign key indexes** - missing these causes major performance problems
- [ ] **Query patterns** considered when creating indexes
- [ ] **N+1 queries** avoided in application code
- [ ] **Large table planning** - consider partitioning for very large tables

---

## 📋 Quick Validation Commands

Run these commands to verify your new table is properly set up:

```sql
-- 1. Check table exists and structure
\d table_name

-- 2. Verify RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'table_name';

-- 3. Check policies exist
SELECT * FROM pg_policies WHERE tablename = 'table_name';

-- 4. Verify indexes exist
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'table_name';

-- 5. Test basic operations
INSERT INTO table_name (required_fields) VALUES (test_values);
SELECT * FROM table_name WHERE user_id = auth.uid();
UPDATE table_name SET field = 'new_value' WHERE id = 'test_id';

-- 6. Check foreign key constraints
SELECT 
  tc.table_name, 
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'table_name';
```

---

## 🎯 Success Criteria

Your new table is ready for production when:

- ✅ **All checklist items** are completed
- ✅ **Tests pass** with realistic data
- ✅ **Performance** meets requirements
- ✅ **Security** policies work correctly
- ✅ **Documentation** is updated
- ✅ **Team** is informed and onboarded

---

## 🔄 Post-Deployment Monitoring

After deployment, monitor for:

- **Query performance** - watch for slow queries
- **Constraint violations** - check error logs
- **Index usage** - verify indexes are being used
- **Data growth** - monitor table size growth
- **Access patterns** - ensure RLS is working as expected

---

## 📞 When to Seek Help

Contact the database team or senior developers if:

- **Complex business logic** requires advanced constraints
- **Performance requirements** are very high
- **Security requirements** are complex
- **Data volume** is expected to be very large
- **Integration** affects multiple systems

---

*Remember: It's better to spend extra time getting the table right initially than to fix problems in production later.*
- [ ]
