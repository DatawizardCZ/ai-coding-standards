-- ==================================================
-- ROW LEVEL SECURITY (RLS) POLICIES TEMPLATE
-- ==================================================
-- Common RLS patterns for Supabase applications
-- Copy and adapt these patterns for your tables
-- ==================================================

-- ==================================================
-- 1. BASIC USER ISOLATION PATTERNS
-- ==================================================

-- Pattern: User can only access their own records
-- Enable RLS first
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Basic CRUD policies for user isolation
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own profile" ON user_profiles
  FOR DELETE USING (user_id = auth.uid());

-- Combined policy for all operations
CREATE POLICY "Users manage own data" ON user_profiles
  FOR ALL USING (user_id = auth.uid());

-- ==================================================
-- 2. ROLE-BASED ACCESS PATTERNS
-- ==================================================

-- Pattern: Role-based access with admin override
CREATE POLICY "Role-based access" ON sensitive_data
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'manager')
    )
  );

-- Pattern: Hierarchical roles
CREATE POLICY "Hierarchical role access" ON user_records
  FOR ALL USING (
    CASE 
      WHEN EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin') THEN
        true  -- Admin sees everything
      WHEN EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'manager') THEN
        user_id = auth.uid() OR created_by = auth.uid()  -- Manager sees own + created records
      ELSE
        user_id = auth.uid()  -- Regular user sees only own records
    END
  );

-- Pattern: Department/team-based access
CREATE POLICY "Department access" ON department_data
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
      AND up.department_id = department_data.department_id
    )
  );

-- ==================================================
-- 3. OWNERSHIP AND SHARING PATTERNS
-- ==================================================

-- Pattern: Owner or shared users can access
CREATE POLICY "Owner and shared access" ON shared_documents
  FOR SELECT USING (
    owner_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM document_shares ds
      WHERE ds.document_id = shared_documents.id
      AND ds.shared_with_user_id = auth.uid()
      AND ds.expires_at > now()
    )
  );

-- Pattern: Team collaboration
CREATE POLICY "Team collaboration access" ON project_files
  FOR ALL USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = project_files.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'editor', 'viewer')
    )
  );

-- Pattern: Organization-wide access
CREATE POLICY "Organization access" ON organization_data
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_organizations uo
      WHERE uo.user_id = auth.uid()
      AND uo.organization_id = organization_data.organization_id
      AND uo.status = 'active'
    )
  );

-- ==================================================
-- 4. STATUS-BASED ACCESS PATTERNS
-- ==================================================

-- Pattern: Status-dependent access
CREATE POLICY "Status-based access" ON documents
  FOR SELECT USING (
    CASE 
      WHEN status = 'public' THEN true
      WHEN status = 'internal' THEN 
        EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid())
      WHEN status = 'private' THEN 
        owner_id = auth.uid()
      ELSE false
    END
  );

-- Pattern: Lifecycle-based permissions
CREATE POLICY "Lifecycle permissions" ON orders
  FOR UPDATE USING (
    CASE 
      WHEN status IN ('draft', 'pending') THEN 
        customer_id = auth.uid() OR 
        EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'staff')
      WHEN status = 'processing' THEN 
        EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role IN ('admin', 'fulfillment'))
      WHEN status IN ('completed', 'cancelled') THEN 
        EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
      ELSE false
    END
  );

-- ==================================================
-- 5. TIME-BASED ACCESS PATTERNS
-- ==================================================

-- Pattern: Time-limited access
CREATE POLICY "Time-limited access" ON temporary_shares
  FOR SELECT USING (
    shared_with = auth.uid() AND
    expires_at > now() AND
    starts_at <= now()
  );

-- Pattern: Recent records only
CREATE POLICY "Recent records access" ON activity_logs
  FOR SELECT USING (
    user_id = auth.uid() AND
    created_at > now() - interval '30 days'
  );

-- Pattern: Business hours access
CREATE POLICY "Business hours access" ON sensitive_operations
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin') OR
    (
      EXTRACT(hour FROM now()) BETWEEN 9 AND 17 AND
      EXTRACT(dow FROM now()) BETWEEN 1 AND 5  -- Monday to Friday
    )
  );

-- Pattern: Editable only for limited time
CREATE POLICY "Limited edit window" ON user_posts
  FOR UPDATE USING (
    user_id = auth.uid() AND
    created_at > now() - interval '24 hours'
  );

-- ==================================================
-- 6. CONDITIONAL ACCESS PATTERNS
-- ==================================================

-- Pattern: Feature flag based access
CREATE POLICY "Feature flag access" ON beta_features
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_features uf
      WHERE uf.user_id = auth.uid()
      AND uf.feature_name = 'beta_access'
      AND uf.enabled = true
    )
  );

-- Pattern: Subscription-based access
CREATE POLICY "Subscription access" ON premium_content
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_subscriptions us
      WHERE us.user_id = auth.uid()
      AND us.plan_type IN ('premium', 'enterprise')
      AND us.status = 'active'
      AND us.expires_at > now()
    )
  );

-- Pattern: Geographic restrictions
CREATE POLICY "Geographic access" ON regional_content
  FOR SELECT USING (
    allowed_regions IS NULL OR
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
      AND up.country_code = ANY(allowed_regions)
    )
  );

-- ==================================================
-- 7. AUDIT AND COMPLIANCE PATTERNS
-- ==================================================

-- Pattern: Audit trail visibility
CREATE POLICY "Audit trail access" ON audit_logs
  FOR SELECT USING (
    target_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
      AND up.role IN ('admin', 'auditor')
    )
  );

-- Pattern: Data retention compliance
CREATE POLICY "Data retention compliance" ON user_data
  FOR SELECT USING (
    user_id = auth.uid() AND
    (
      deleted_at IS NULL OR
      deleted_at > now() - interval '7 years'  -- Legal retention period
    )
  );

-- ==================================================
-- 8. PERFORMANCE-OPTIMIZED PATTERNS
-- ==================================================

-- Pattern: Index-friendly policies
-- Make sure to create: CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE POLICY "Index-optimized user access" ON orders
  FOR ALL USING (user_id = auth.uid());

-- Pattern: Composite index optimization
-- Make sure to create: CREATE INDEX idx_documents_user_status ON documents(user_id, status);
CREATE POLICY "Composite index optimized" ON documents
  FOR SELECT USING (
    user_id = auth.uid() AND
    status != 'deleted'
  );

-- ==================================================
-- 9. SPECIAL OPERATIONS PATTERNS
-- ==================================================

-- Pattern: Insert-only restrictions
CREATE POLICY "Insert only for users" ON user_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "No updates allowed" ON user_logs
  FOR UPDATE USING (false);  -- Prevent all updates

CREATE POLICY "Admin delete only" ON user_logs
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- Pattern: Read-only for regular users
CREATE POLICY "Read-only for users" ON system_settings
  FOR SELECT USING (
    is_public = true OR
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin write access" ON system_settings
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin update access" ON system_settings
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ==================================================
-- 10. HELPER FUNCTIONS FOR POLICIES
-- ==================================================

-- Function to check user role (reusable in policies)
CREATE OR REPLACE FUNCTION user_has_role(role_name TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role = role_name
    AND deleted_at IS NULL
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Function to check organization membership
CREATE OR REPLACE FUNCTION user_in_organization(org_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_organizations 
    WHERE user_id = auth.uid() 
    AND organization_id = org_id
    AND status = 'active'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Function to check team membership
CREATE OR REPLACE FUNCTION user_in_team(team_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM team_members 
    WHERE user_id = auth.uid() 
    AND team_id = team_id
    AND status = 'active'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Using helper functions in policies
CREATE POLICY "Helper function example" ON team_documents
  FOR ALL USING (user_in_team(team_id));

-- ==================================================
-- 11. POLICY MANAGEMENT PATTERNS
-- ==================================================

-- Pattern: Disable all policies temporarily (for maintenance)
-- ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- Pattern: Drop and recreate policies safely
-- DROP POLICY IF EXISTS "old_policy_name" ON table_name;
-- CREATE POLICY "new_policy_name" ON table_name ...;

-- Pattern: Test policies with specific users
-- SET LOCAL rls.current_user_id = 'user-uuid-here';
-- SELECT * FROM protected_table;

-- ==================================================
-- 12. POLICY TESTING STRATEGIES
-- ==================================================

/*
-- Test RLS policies thoroughly:

1. Test with different user roles
2. Test edge cases (null values, missing relationships)
3. Test performance with large datasets
4. Test policy interactions with application queries

-- Example test cases:
-- 1. User can see own data
SELECT * FROM user_profiles WHERE user_id = auth.uid();

-- 2. User cannot see other users' data
-- (This should return empty when tested with different user)
SELECT * FROM user_profiles WHERE user_id != auth.uid();

-- 3. Admin can see all data
-- (Test with admin user)
SELECT count(*) FROM user_profiles;

-- 4. Performance test
EXPLAIN ANALYZE SELECT * FROM large_table WHERE user_id = auth.uid();
*/

-- ==================================================
-- POLICY BEST PRACTICES
-- ==================================================

/*
1. SECURITY:
   - Always enable RLS on user-facing tables
   - Test policies with different user scenarios
   - Use helper functions for complex permission logic
   - Avoid overly complex policies that are hard to audit

2. PERFORMANCE:
   - Create indexes that support your RLS policies
   - Use simple conditions when possible
   - Avoid correlated subqueries in hot paths
   - Monitor query performance with RLS enabled

3. MAINTAINABILITY:
   - Name policies descriptively
   - Document complex permission logic
   - Use consistent patterns across similar tables
   - Group related policies together

4. TESTING:
   - Test policies in development environment
   - Create automated tests for critical policies
   - Test with realistic data volumes
   - Verify policies work with your application queries

5. DEBUGGING:
   - Use EXPLAIN to understand query plans
   - Test policies in isolation
   - Check for policy conflicts
   - Monitor for unexpected access patterns
*/

-- ==================================================
-- COMMON GOTCHAS AND SOLUTIONS
-- ==================================================

/*
1. POLICY NOT APPLYING:
   - Make sure RLS is enabled: ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
   - Check policy names for conflicts
   - Verify auth.uid() returns expected value

2. PERFORMANCE ISSUES:
   - Add indexes for policy conditions
   - Simplify complex policy logic
   - Consider materialized views for heavy aggregations

3. ACCESS DENIED ERRORS:
   - Check if user meets policy conditions
   - Verify foreign key relationships exist
   - Test with different user roles

4. POLICY CONFLICTS:
   - Multiple policies are OR'd together
   - More restrictive policies don't override permissive ones
   - Use specific policy names to avoid confusion
*/
