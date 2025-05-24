-- ==================================================
-- MIGRATION TEMPLATE
-- ==================================================
-- File: migration_YYYY_MM_DD_HH_MM_description.sql
-- Description: [Brief description of what this migration does]
-- Author: [Your name]
-- Date: [YYYY-MM-DD]
-- ==================================================

-- ALWAYS wrap migrations in a transaction
BEGIN;

-- ==================================================
-- MIGRATION METADATA
-- ==================================================
-- Optional: Track migration history
-- INSERT INTO migration_history (version, description, applied_at)
-- VALUES ('YYYY_MM_DD_HH_MM', 'Brief description', now());

-- ==================================================
-- SAFETY CHECKS
-- ==================================================
-- Check if migration has already been applied
DO $migration_check$
BEGIN
  -- Example: Check if column already exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'target_table' 
    AND column_name = 'new_column'
  ) THEN
    RAISE NOTICE 'Migration already applied: new_column exists';
    -- Optionally stop here or continue with other changes
  END IF;
  
  -- Example: Check if table exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'required_table'
  ) THEN
    RAISE EXCEPTION 'Prerequisites not met: required_table does not exist';
  END IF;
END $migration_check$;

-- ==================================================
-- SCHEMA CHANGES
-- ==================================================

-- --------------------------------------------------
-- 1. CREATE NEW TABLES
-- --------------------------------------------------
-- Use IF NOT EXISTS for idempotency
CREATE TABLE IF NOT EXISTS new_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Add comments
COMMENT ON TABLE new_table IS 'Description of the new table purpose';

-- --------------------------------------------------
-- 2. ADD COLUMNS (Always add as nullable first)
-- --------------------------------------------------
DO $add_columns$
BEGIN
  -- Check if column doesn't exist before adding
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'existing_table' 
    AND column_name = 'new_column'
  ) THEN
    ALTER TABLE existing_table ADD COLUMN new_column VARCHAR(100);
    
    -- Add comment
    COMMENT ON COLUMN existing_table.new_column IS 'Description of new column';
  END IF;
END $add_columns$;

-- --------------------------------------------------
-- 3. MODIFY EXISTING COLUMNS
-- --------------------------------------------------
-- Change column type (be careful with data compatibility)
-- ALTER TABLE existing_table ALTER COLUMN column_name TYPE new_type;

-- Add NOT NULL constraint (ensure no nulls first)
-- UPDATE existing_table SET column_name = 'default_value' WHERE column_name IS NULL;
-- ALTER TABLE existing_table ALTER COLUMN column_name SET NOT NULL;

-- Add DEFAULT value
-- ALTER TABLE existing_table ALTER COLUMN column_name SET DEFAULT 'default_value';

-- --------------------------------------------------
-- 4. ADD CONSTRAINTS
-- --------------------------------------------------
-- Add constraints with validation
DO $add_constraints$
BEGIN
  -- Check if constraint doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'existing_table' 
    AND constraint_name = 'check_status_values'
  ) THEN
    -- Add constraint as NOT VALID first (for large tables)
    ALTER TABLE existing_table 
    ADD CONSTRAINT check_status_values 
    CHECK (status IN ('active', 'inactive', 'pending')) NOT VALID;
    
    -- Then validate it
    ALTER TABLE existing_table VALIDATE CONSTRAINT check_status_values;
  END IF;
END $add_constraints$;

-- Foreign key constraints
DO $add_foreign_keys$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'child_table' 
    AND constraint_name = 'fk_child_parent_id'
  ) THEN
    ALTER TABLE child_table 
    ADD CONSTRAINT fk_child_parent_id 
    FOREIGN KEY (parent_id) REFERENCES parent_table(id);
  END IF;
END $add_foreign_keys$;

-- --------------------------------------------------
-- 5. CREATE INDEXES
-- --------------------------------------------------
-- Create indexes concurrently (non-blocking)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_table_column 
ON table_name(column_name);

-- Composite indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_table_multi_column 
ON table_name(column1, column2);

-- Partial indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_table_partial 
ON table_name(column_name) 
WHERE condition = true;

-- GIN indexes for JSONB/arrays
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_table_jsonb 
ON table_name USING GIN(jsonb_column);

-- --------------------------------------------------
-- 6. CREATE/UPDATE FUNCTIONS
-- --------------------------------------------------
CREATE OR REPLACE FUNCTION updated_function_name()
RETURNS trigger AS $$
BEGIN
  -- Function logic here
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------------
-- 7. CREATE/UPDATE TRIGGERS
-- --------------------------------------------------
-- Drop trigger if exists, then recreate
DROP TRIGGER IF EXISTS trigger_name ON table_name;
CREATE TRIGGER trigger_name
  BEFORE UPDATE ON table_name
  FOR EACH ROW EXECUTE FUNCTION updated_function_name();

-- --------------------------------------------------
-- 8. UPDATE ROW LEVEL SECURITY
-- --------------------------------------------------
-- Enable RLS if not already enabled
DO $enable_rls$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'new_table' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;
  END IF;
END $enable_rls$;

-- Create/update policies
DROP POLICY IF EXISTS "users_own_data" ON new_table;
CREATE POLICY "users_own_data" ON new_table
  FOR ALL USING (user_id = auth.uid());

-- --------------------------------------------------
-- 9. ENABLE REALTIME (Supabase)
-- --------------------------------------------------
-- ALTER PUBLICATION supabase_realtime ADD TABLE new_table;

-- ==================================================
-- DATA MIGRATIONS
-- ==================================================

-- --------------------------------------------------
-- 1. DATA UPDATES (Be careful with large tables)
-- --------------------------------------------------
-- For large tables, consider batching updates
-- UPDATE table_name 
-- SET column_name = new_value 
-- WHERE condition;

-- Example: Populate new column with computed values
-- UPDATE existing_table 
-- SET new_column = CASE 
--   WHEN some_condition THEN 'value1'
--   ELSE 'value2'
-- END
-- WHERE new_column IS NULL;

-- --------------------------------------------------
-- 2. DATA CLEANUP
-- --------------------------------------------------
-- Remove old/invalid data if needed
-- DELETE FROM table_name WHERE condition;

-- --------------------------------------------------
-- 3. SEED DATA
-- --------------------------------------------------
-- Insert reference/lookup data
-- INSERT INTO lookup_table (code, name, description) VALUES
--   ('CODE1', 'Name 1', 'Description 1'),
--   ('CODE2', 'Name 2', 'Description 2')
-- ON CONFLICT (code) DO NOTHING;

-- ==================================================
-- PERFORMANCE OPTIMIZATIONS
-- ==================================================

-- Update table statistics
ANALYZE new_table;
ANALYZE existing_table;

-- Vacuum if needed (for large data changes)
-- VACUUM ANALYZE table_name;

-- ==================================================
-- VALIDATION CHECKS
-- ==================================================
-- Verify migration worked correctly
DO $validation$
DECLARE
  record_count INTEGER;
BEGIN
  -- Check that data was migrated correctly
  SELECT COUNT(*) INTO record_count FROM new_table;
  
  IF record_count = 0 THEN
    RAISE NOTICE 'Warning: new_table is empty after migration';
  ELSE
    RAISE NOTICE 'Migration successful: % records in new_table', record_count;
  END IF;
  
  -- Verify constraints are working
  -- Add validation queries here
END $validation$;

-- ==================================================
-- ROLLBACK PLAN (Document but don't execute)
-- ==================================================
/*
ROLLBACK INSTRUCTIONS (if migration needs to be reverted):

1. Remove new columns:
   ALTER TABLE existing_table DROP COLUMN IF EXISTS new_column;

2. Drop new tables:
   DROP TABLE IF EXISTS new_table CASCADE;

3. Remove indexes:
   DROP INDEX CONCURRENTLY IF EXISTS idx_table_column;

4. Remove constraints:
   ALTER TABLE existing_table DROP CONSTRAINT IF EXISTS check_status_values;

5. Restore old data (if data was modified):
   -- Restore from backup or previous values

6. Remove triggers:
   DROP TRIGGER IF EXISTS trigger_name ON table_name;

7. Disable RLS policies:
   DROP POLICY IF EXISTS "users_own_data" ON new_table;

Note: Test rollback on development environment first!
*/

-- ==================================================
-- COMMIT MIGRATION
-- ==================================================
-- If everything looks good, commit the transaction
COMMIT;

-- If there are issues, rollback instead:
-- ROLLBACK;

-- ==================================================
-- POST-MIGRATION TASKS
-- ==================================================
-- 1. Monitor application logs for errors
-- 2. Check query performance
-- 3. Verify application functionality
-- 4. Update documentation
-- 5. Notify team of schema changes
-- 6. Schedule follow-up performance review

-- ==================================================
-- MIGRATION NOTES
-- ==================================================
-- 1. Always test migrations on development/staging first
-- 2. Have a rollback plan ready
-- 3. Consider downtime requirements for large changes
-- 4. Monitor database performance after deployment
-- 5. Keep migrations small and focused
-- 6. Document breaking changes clearly
-- 7. Use transactions to ensure atomicity
-- 8. Validate data integrity after migration
