-- ==================================================
-- STANDARD TABLE TEMPLATE
-- ==================================================
-- Copy this template when creating new tables
-- Replace 'template_table' with your actual table name
-- Customize fields according to your business needs
-- ==================================================

-- Enable required extensions (if not already enabled)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create the main table
CREATE TABLE template_table (
  -- ==================================================
  -- PRIMARY KEY
  -- ==================================================
  -- Use UUID for main business entities (distributed-friendly)
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Use SERIAL for lookup/reference tables (more efficient)
  -- id SERIAL PRIMARY KEY,
  
  -- ==================================================
  -- BUSINESS FIELDS
  -- ==================================================
  -- Core business data - customize these fields
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'active' 
    CHECK (status IN ('active', 'inactive', 'archived', 'pending')),
  
  -- Numeric fields
  amount DECIMAL(10,2),
  quantity INTEGER,
  priority INTEGER DEFAULT 0,
  
  -- Boolean fields (use consistent naming)
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT false,
  
  -- ==================================================
  -- FOREIGN KEY RELATIONSHIPS
  -- ==================================================
  -- Always name foreign keys consistently: [table]_id
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  parent_id UUID REFERENCES template_table(id) ON DELETE CASCADE,
  
  -- ==================================================
  -- FLEXIBLE DATA STORAGE
  -- ==================================================
  -- Use JSONB for flexible metadata
  metadata JSONB DEFAULT '{}',
  
  -- Use arrays for simple tag systems
  tags TEXT[] DEFAULT '{}',
  
  -- Use TEXT arrays for simple lists
  options TEXT[] DEFAULT '{}',
  
  -- ==================================================
  -- AUDIT FIELDS (REQUIRED FOR ALL TABLES)
  -- ==================================================
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  
  -- Track who created/updated (for user-facing tables)
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  
  -- Soft delete support (optional but recommended)
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES users(id)
);

-- ==================================================
-- COMMENTS (Document your schema)
-- ==================================================
COMMENT ON TABLE template_table IS 'Description of what this table stores and its purpose';
COMMENT ON COLUMN template_table.status IS 'Current status of the record (active, inactive, archived, pending)';
COMMENT ON COLUMN template_table.metadata IS 'Flexible JSON storage for additional properties';
COMMENT ON COLUMN template_table.tags IS 'Array of tags for categorization and search';

-- ==================================================
-- INDEXES (Critical for performance)
-- ==================================================

-- Primary foreign key indexes (ALWAYS CREATE THESE)
CREATE INDEX idx_template_table_user_id ON template_table(user_id);
CREATE INDEX idx_template_table_category_id ON template_table(category_id);
CREATE INDEX idx_template_table_parent_id ON template_table(parent_id);

-- Status and filtering indexes
CREATE INDEX idx_template_table_status ON template_table(status);
CREATE INDEX idx_template_table_is_active ON template_table(is_active);

-- Timestamp indexes (for date range queries)
CREATE INDEX idx_template_table_created_at ON template_table(created_at);
CREATE INDEX idx_template_table_updated_at ON template_table(updated_at);

-- Composite indexes for common query patterns
CREATE INDEX idx_template_table_user_status ON template_table(user_id, status);
CREATE INDEX idx_template_table_status_created ON template_table(status, created_at);

-- Partial indexes (for specific use cases)
CREATE INDEX idx_template_table_active_created ON template_table(created_at) 
WHERE is_active = true AND deleted_at IS NULL;

-- GIN indexes for arrays and JSONB
CREATE INDEX idx_template_table_tags_gin ON template_table USING GIN(tags);
CREATE INDEX idx_template_table_metadata_gin ON template_table USING GIN(metadata);

-- Text search index (if needed)
-- CREATE INDEX idx_template_table_search ON template_table 
-- USING GIN(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- ==================================================
-- ROW LEVEL SECURITY (Required for user-facing tables)
-- ==================================================

-- Enable RLS
ALTER TABLE template_table ENABLE ROW LEVEL SECURITY;

-- Basic user isolation policy
CREATE POLICY "Users can view own records" ON template_table
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own records" ON template_table
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own records" ON template_table
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own records" ON template_table
  FOR DELETE USING (user_id = auth.uid());

-- Admin access policy (if using roles)
CREATE POLICY "Admins have full access" ON template_table
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- ==================================================
-- TRIGGERS
-- ==================================================

-- Auto-update timestamp trigger (ALWAYS ADD THIS)
CREATE TRIGGER template_table_updated_at
  BEFORE UPDATE ON template_table
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit trigger (optional but recommended)
-- CREATE TRIGGER template_table_audit
--   AFTER INSERT OR UPDATE OR DELETE ON template_table
--   FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- Soft delete trigger (if using soft deletes)
-- CREATE TRIGGER template_table_soft_delete
--   BEFORE DELETE ON template_table
--   FOR EACH ROW EXECUTE FUNCTION soft_delete_trigger();

-- ==================================================
-- FUNCTIONS (Optional - for complex business logic)
-- ==================================================

-- Example: Get records with computed fields
CREATE OR REPLACE FUNCTION get_template_table_summary(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE(
  id UUID,
  name TEXT,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  days_since_created INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.name,
    t.status,
    t.created_at,
    EXTRACT(days FROM now() - t.created_at)::INTEGER as days_since_created
  FROM template_table t
  WHERE t.user_id = p_user_id
    AND t.deleted_at IS NULL
  ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- VIEWS (Optional - for common queries)
-- ==================================================

-- Example: Active records view
CREATE VIEW template_table_active_v AS
SELECT 
  id,
  name,
  description,
  status,
  user_id,
  created_at,
  updated_at
FROM template_table
WHERE is_active = true 
  AND deleted_at IS NULL;

-- ==================================================
-- REALTIME (Enable if needed)
-- ==================================================

-- Enable realtime updates (Supabase)
-- ALTER PUBLICATION supabase_realtime ADD TABLE template_table;

-- ==================================================
-- INITIAL DATA (Optional - for lookup tables)
-- ==================================================

-- Insert default/seed data if needed
-- INSERT INTO template_table (name, status, is_active) VALUES
--   ('Default Category', 'active', true),
--   ('Sample Entry', 'active', true);

-- ==================================================
-- SECURITY NOTES
-- ==================================================
-- 1. Always enable RLS on user-facing tables
-- 2. Test RLS policies with different user roles
-- 3. Use SECURITY DEFINER functions carefully
-- 4. Validate all user inputs in application layer
-- 5. Monitor for N+1 query problems with foreign keys
-- 6. Consider data retention policies for audit fields

-- ==================================================
-- PERFORMANCE NOTES
-- ==================================================
-- 1. Add indexes for all foreign keys
-- 2. Create composite indexes for common WHERE clauses
-- 3. Use partial indexes for frequently filtered subsets
-- 4. Monitor query performance with EXPLAIN ANALYZE
-- 5. Consider partitioning for very large tables
-- 6. Regular VACUUM and ANALYZE for optimal performance
