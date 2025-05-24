-- ==================================================
-- ADVANCED DATABASE PATTERNS
-- ==================================================
-- Complex patterns for SaaS, multi-tenant, and enterprise applications
-- Focus on scalability, flexibility, and advanced business logic
-- ==================================================

-- ==================================================
-- 1. MULTI-TENANCY PATTERN (Perfect for Multi-Gym Management)
-- ==================================================
-- Supports multiple organizations/gyms with complete data isolation

-- Organization/Tenant management
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL, -- for subdomain routing
  domain VARCHAR(255), -- custom domain support
  logo_url TEXT,
  timezone VARCHAR(50) DEFAULT 'UTC',
  locale VARCHAR(10) DEFAULT 'en',
  subscription_plan VARCHAR(50) DEFAULT 'basic',
  subscription_status VARCHAR(20) DEFAULT 'active' CHECK (subscription_status IN ('active', 'suspended', 'cancelled', 'trial')),
  trial_ends_at TIMESTAMP WITH TIME ZONE,
  subscription_expires_at TIMESTAMP WITH TIME ZONE,
  settings JSONB DEFAULT '{}', -- Organization-specific settings
  billing_email VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Locations within organizations (gyms/branches)
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL, -- organization-scoped slug
  address_line1 VARCHAR(255),
  address_line2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(2) DEFAULT 'US',
  phone VARCHAR(20),
  email VARCHAR(255),
  timezone VARCHAR(50),
  operating_hours JSONB DEFAULT '{}', -- {"monday": {"open": "06:00", "close": "22:00"}}
  amenities TEXT[],
  max_capacity INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(organization_id, slug)
);

-- Organization membership/user relationships
CREATE TABLE organization_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'member', -- owner, admin, manager, trainer, member
  permissions JSONB DEFAULT '[]', -- Specific permissions array
  locations TEXT[] DEFAULT '{}', -- Location IDs user has access to (empty = all)
  invited_by UUID REFERENCES auth.users(id),
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  joined_at TIMESTAMP WITH TIME ZONE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'removed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(organization_id, user_id)
);

-- RLS policies for multi-tenancy
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_memberships ENABLE ROW LEVEL SECURITY;

-- Users can only see organizations they belong to
CREATE POLICY "Users see own organizations" ON organizations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM organization_memberships om
      WHERE om.organization_id = organizations.id
      AND om.user_id = auth.uid()
      AND om.status = 'active'
    )
  );

-- Users can see locations in their organizations
CREATE POLICY "Users see organization locations" ON locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM organization_memberships om
      WHERE om.organization_id = locations.organization_id
      AND om.user_id = auth.uid()
      AND om.status = 'active'
      AND (
        om.locations = '{}' OR -- Access to all locations
        locations.id::text = ANY(om.locations) -- Access to specific locations
      )
    )
  );

-- ==================================================
-- 2. ADVANCED ROLE-BASED ACCESS CONTROL (RBAC)
-- ==================================================
-- Hierarchical roles with granular permissions

-- Permission definitions
CREATE TABLE permissions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL, -- e.g., 'members.read', 'trainers.manage'
  description TEXT,
  resource VARCHAR(100) NOT NULL, -- e.g., 'members', 'classes', 'equipment'
  action VARCHAR(50) NOT NULL, -- e.g., 'read', 'write', 'delete', 'manage'
  scope VARCHAR(50) DEFAULT 'organization', -- 'global', 'organization', 'location'
  is_system BOOLEAN DEFAULT false, -- System permissions cannot be deleted
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Role definitions with hierarchical structure
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  level INTEGER DEFAULT 0, -- Hierarchy level (higher = more senior)
  inherits_from UUID REFERENCES roles(id), -- Role inheritance
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(organization_id, name)
);

-- Role-permission mapping
CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id INTEGER NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  granted BOOLEAN DEFAULT true, -- Allow explicit denial
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(role_id, permission_id)
);

-- User role assignments (can have multiple roles)
CREATE TABLE user_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  location_ids TEXT[] DEFAULT '{}', -- Specific locations (empty = all)
  granted_by UUID REFERENCES auth.users(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id, role_id, organization_id)
);

-- Function to check if user has permission
CREATE OR REPLACE FUNCTION user_has_permission(
  p_user_id UUID,
  p_permission_name VARCHAR(100),
  p_organization_id UUID DEFAULT NULL,
  p_location_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  has_permission BOOLEAN := FALSE;
BEGIN
  -- Check direct role permissions
  SELECT EXISTS (
    SELECT 1 
    FROM user_role_assignments ura
    JOIN role_permissions rp ON ura.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE ura.user_id = p_user_id
      AND p.name = p_permission_name
      AND ura.is_active = true
      AND (ura.expires_at IS NULL OR ura.expires_at > now())
      AND (p_organization_id IS NULL OR ura.organization_id = p_organization_id)
      AND (
        p_location_id IS NULL OR 
        ura.location_ids = '{}' OR 
        p_location_id::text = ANY(ura.location_ids)
      )
      AND rp.granted = true
  ) INTO has_permission;
  
  RETURN has_permission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 3. SUBSCRIPTION & BILLING PATTERN
-- ==================================================
-- Flexible subscription management for SaaS

-- Subscription plans
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2),
  price_yearly DECIMAL(10,2),
  max_locations INTEGER, -- NULL = unlimited
  max_members INTEGER, -- NULL = unlimited
  max_trainers INTEGER, -- NULL = unlimited
  max_storage_gb INTEGER, -- NULL = unlimited
  features JSONB DEFAULT '[]', -- Array of included features
  trial_days INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Organization subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('trial', 'active', 'past_due', 'cancelled', 'expired')),
  billing_cycle VARCHAR(20) NOT NULL CHECK (billing_cycle IN ('monthly', 'yearly')),
  current_period_start DATE NOT NULL,
  current_period_end DATE NOT NULL,
  trial_start DATE,
  trial_end DATE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancel_at_period_end BOOLEAN DEFAULT false,
  external_subscription_id VARCHAR(255), -- Stripe/payment processor ID
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(organization_id) -- One active subscription per org
);

-- Usage tracking for billing
CREATE TABLE usage_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  metric_name VARCHAR(100) NOT NULL, -- 'active_members', 'storage_used', 'api_calls'
  metric_value DECIMAL(12,2) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  metadata JSONB DEFAULT '{}',
  UNIQUE(organization_id, metric_name, period_start, period_end)
);

-- Billing events and invoices
CREATE TABLE billing_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id),
  event_type VARCHAR(50) NOT NULL, -- 'invoice_created', 'payment_succeeded', 'payment_failed'
  amount DECIMAL(10,2),
  currency VARCHAR(3) DEFAULT 'USD',
  external_event_id VARCHAR(255), -- Payment processor event ID
  event_data JSONB DEFAULT '{}',
  processed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- ==================================================
-- 4. FEATURE FLAGS PATTERN
-- ==================================================
-- Dynamic feature control per organization/user

-- Feature definitions
CREATE TABLE features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  feature_type VARCHAR(20) DEFAULT 'boolean' CHECK (feature_type IN ('boolean', 'string', 'number', 'json')),
  default_value TEXT DEFAULT 'false',
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Organization-level feature flags
CREATE TABLE organization_features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
  is_enabled BOOLEAN DEFAULT false,
  value TEXT, -- For non-boolean features
  enabled_by UUID REFERENCES auth.users(id),
  enabled_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(organization_id, feature_id)
);

-- User-level feature flags (overrides organization)
CREATE TABLE user_features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
  is_enabled BOOLEAN DEFAULT false,
  value TEXT,
  enabled_by UUID REFERENCES auth.users(id),
  enabled_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id, organization_id, feature_id)
);

-- Function to check feature flag
CREATE OR REPLACE FUNCTION is_feature_enabled(
  p_feature_name VARCHAR(100),
  p_organization_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
DECLARE
  feature_enabled BOOLEAN := FALSE;
  feature_record RECORD;
BEGIN
  -- Get feature definition
  SELECT * INTO feature_record FROM features WHERE name = p_feature_name;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Check user-level flag first (highest priority)
  IF p_user_id IS NOT NULL AND p_organization_id IS NOT NULL THEN
    SELECT is_enabled INTO feature_enabled
    FROM user_features uf
    WHERE uf.user_id = p_user_id
      AND uf.organization_id = p_organization_id
      AND uf.feature_id = feature_record.id
      AND (uf.expires_at IS NULL OR uf.expires_at > now());
    
    IF FOUND THEN
      RETURN feature_enabled;
    END IF;
  END IF;
  
  -- Check organization-level flag
  IF p_organization_id IS NOT NULL THEN
    SELECT is_enabled INTO feature_enabled
    FROM organization_features of
    WHERE of.organization_id = p_organization_id
      AND of.feature_id = feature_record.id
      AND (of.expires_at IS NULL OR of.expires_at > now());
    
    IF FOUND THEN
      RETURN feature_enabled;
    END IF;
  END IF;
  
  -- Return default value
  RETURN (feature_record.default_value = 'true');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 5. TEAM & DEPARTMENT MANAGEMENT PATTERN
-- ==================================================
-- Hierarchical team structure within organizations

-- Departments within organizations
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  parent_department_id UUID REFERENCES departments(id),
  manager_id UUID REFERENCES auth.users(id),
  budget DECIMAL(12,2),
  cost_center VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Teams within departments
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  department_id UUID REFERENCES departments(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  team_lead_id UUID REFERENCES auth.users(id),
  location_ids TEXT[] DEFAULT '{}', -- Teams can be tied to specific locations
  max_members INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Team membership
CREATE TABLE team_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member', -- lead, member, contributor
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  left_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(team_id, user_id)
);

-- ==================================================
-- 6. WORKFLOW & APPROVAL SYSTEM PATTERN
-- ==================================================
-- Multi-step approval processes

-- Workflow definitions
CREATE TABLE workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  entity_type VARCHAR(100) NOT NULL, -- 'member_application', 'expense_report', etc.
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Workflow steps
CREATE TABLE workflow_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
  step_name VARCHAR(255) NOT NULL,
  step_order INTEGER NOT NULL,
  approver_type VARCHAR(50) NOT NULL, -- 'role', 'user', 'department_manager'
  approver_value TEXT NOT NULL, -- Role name, user ID, or 'department_manager'
  required_approvals INTEGER DEFAULT 1,
  allow_parallel BOOLEAN DEFAULT false,
  auto_approve_conditions JSONB, -- Conditions for auto-approval
  timeout_hours INTEGER, -- Auto-escalate after timeout
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Workflow instances
CREATE TABLE workflow_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES workflows(id),
  entity_type VARCHAR(100) NOT NULL,
  entity_id UUID NOT NULL,
  current_step_id UUID REFERENCES workflow_steps(id),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'expired')),
  submitted_by UUID NOT NULL REFERENCES auth.users(id),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  data JSONB DEFAULT '{}', -- Context data for the workflow
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Approval actions
CREATE TABLE workflow_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_instance_id UUID NOT NULL REFERENCES workflow_instances(id) ON DELETE CASCADE,
  step_id UUID NOT NULL REFERENCES workflow_steps(id),
  approver_id UUID NOT NULL REFERENCES auth.users(id),
  action VARCHAR(20) NOT NULL CHECK (action IN ('approved', 'rejected', 'delegated')),
  comments TEXT,
  delegated_to UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- ==================================================
-- 7. ADVANCED AUDIT & COMPLIANCE PATTERN
-- ==================================================
-- Enhanced audit trail with compliance features

-- Audit categories for compliance
CREATE TABLE audit_categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  retention_days INTEGER, -- Legal retention requirement
  requires_approval BOOLEAN DEFAULT false,
  compliance_framework VARCHAR(100), -- GDPR, HIPAA, SOX, etc.
  is_active BOOLEAN DEFAULT true
);

-- Enhanced audit logs with compliance features
CREATE TABLE compliance_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  category_id INTEGER REFERENCES audit_categories(id),
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  operation VARCHAR(10) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[],
  user_id UUID REFERENCES auth.users(id),
  session_id UUID,
  ip_address INET,
  user_agent TEXT,
  location_id UUID REFERENCES locations(id),
  business_justification TEXT, -- Required for sensitive operations
  approved_by UUID REFERENCES auth.users(id),
  risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  compliance_flags TEXT[], -- Array of compliance concerns
  retention_until DATE, -- When this log can be purged
  is_sensitive BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Data access logs for compliance
CREATE TABLE data_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  resource_type VARCHAR(100) NOT NULL,
  resource_id UUID NOT NULL,
  access_type VARCHAR(50) NOT NULL, -- 'view', 'export', 'print', 'api'
  purpose TEXT, -- Business purpose for access
  data_classification VARCHAR(20) DEFAULT 'internal', -- public, internal, confidential, restricted
  ip_address INET,
  location_id UUID REFERENCES locations(id),
  session_duration INTEGER, -- Seconds
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- ==================================================
-- 8. MULTI-LOCATION OPERATIONAL PATTERN
-- ==================================================
-- Specific patterns for multi-location business operations

-- Location hierarchies and relationships
CREATE TABLE location_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_location_id UUID NOT NULL REFERENCES locations(id),
  child_location_id UUID NOT NULL REFERENCES locations(id),
  relationship_type VARCHAR(50) NOT NULL, -- 'region', 'district', 'franchise'
  effective_from DATE DEFAULT CURRENT_DATE,
  effective_until DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(parent_location_id, child_location_id)
);

-- Location-specific configurations
CREATE TABLE location_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  config_key VARCHAR(100) NOT NULL,
  config_value TEXT NOT NULL,
  data_type VARCHAR(20) DEFAULT 'string',
  is_inheritable BOOLEAN DEFAULT false, -- Can child locations inherit this?
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(location_id, config_key)
);

-- Cross-location resource sharing
CREATE TABLE location_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type VARCHAR(100) NOT NULL, -- 'equipment', 'trainer', 'class'
  resource_id UUID NOT NULL,
  home_location_id UUID NOT NULL REFERENCES locations(id),
  shared_with_locations TEXT[] DEFAULT '{}', -- Location IDs
  sharing_rules JSONB DEFAULT '{}', -- Booking rules, availability, etc.
  is_shareable BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Location performance metrics
CREATE TABLE location_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID NOT NULL REFERENCES locations(id),
  metric_date DATE NOT NULL,
  metric_name VARCHAR(100) NOT NULL,
  metric_value DECIMAL(12,2) NOT NULL,
  metric_unit VARCHAR(50), -- 'members', 'revenue', 'classes', etc.
  comparison_value DECIMAL(12,2), -- Previous period for comparison
  target_value DECIMAL(12,2), -- Goal/target
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(location_id, metric_date, metric_name)
);

-- ==================================================
-- 9. INDEXES FOR ADVANCED PATTERNS
-- ==================================================

-- Multi-tenancy indexes
CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_subscription_status ON organizations(subscription_status);
CREATE INDEX idx_locations_organization_id ON locations(organization_id);
CREATE INDEX idx_organization_memberships_user_org ON organization_memberships(user_id, organization_id);
CREATE INDEX idx_organization_memberships_org_role ON organization_memberships(organization_id, role);

-- RBAC indexes
CREATE INDEX idx_user_role_assignments_user_org ON user_role_assignments(user_id, organization_id);
CREATE INDEX idx_user_role_assignments_role ON user_role_assignments(role_id);
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);

-- Subscription indexes
CREATE INDEX idx_subscriptions_org_status ON subscriptions(organization_id, status);
CREATE INDEX idx_usage_metrics_org_period ON usage_metrics(organization_id, period_start, period_end);

-- Feature flags indexes
CREATE INDEX idx_organization_features_org_feature ON organization_features(organization_id, feature_id);
CREATE INDEX idx_user_features_user_org_feature ON user_features(user_id, organization_id, feature_id);

-- Team management indexes
CREATE INDEX idx_teams_organization_id ON teams(organization_id);
CREATE INDEX idx_team_memberships_team_user ON team_memberships(team_id, user_id);
CREATE INDEX idx_team_memberships_user ON team_memberships(user_id);

-- Workflow indexes
CREATE INDEX idx_workflow_instances_entity ON workflow_instances(entity_type, entity_id);
CREATE INDEX idx_workflow_instances_status ON workflow_instances(status);
CREATE INDEX idx_workflow_approvals_instance ON workflow_approvals(workflow_instance_id);

-- Audit indexes
CREATE INDEX idx_compliance_audit_logs_org_table ON compliance_audit_logs(organization_id, table_name);
CREATE INDEX idx_compliance_audit_logs_record ON compliance_audit_logs(table_name, record_id);
CREATE INDEX idx_compliance_audit_logs_user ON compliance_audit_logs(user_id);
CREATE INDEX idx_compliance_audit_logs_created_at ON compliance_audit_logs(created_at);
CREATE INDEX idx_data_access_logs_user_resource ON data_access_logs(user_id, resource_type, resource_id);

-- Location indexes
CREATE INDEX idx_location_relationships_parent ON location_relationships(parent_location_id);
CREATE INDEX idx_location_relationships_child ON location_relationships(child_location_id);
CREATE INDEX idx_location_configurations_location ON location_configurations(location_id);
CREATE INDEX idx_location_resources_home ON location_resources(home_location_id);
CREATE INDEX idx_location_metrics_location_date ON location_metrics(location_id, metric_date);

-- ==================================================
-- 10. HELPER FUNCTIONS FOR ADVANCED PATTERNS
-- ==================================================

-- Get user's organizations
CREATE OR REPLACE FUNCTION get_user_organizations(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE(
  organization_id UUID,
  organization_name TEXT,
  role TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.name,
    om.role,
    om.status
  FROM organizations o
  JOIN organization_memberships om ON o.id = om.organization_id
  WHERE om.user_id = p_user_id
    AND om.status = 'active'
    AND o.is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's accessible locations
CREATE OR REPLACE FUNCTION get_user_locations(
  p_user_id UUID DEFAULT auth.uid(),
  p_organization_id UUID DEFAULT NULL
)
RETURNS TABLE(
  location_id UUID,
  location_name TEXT,
  organization_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.id,
    l.name,
    o.name
  FROM locations l
  JOIN organizations o ON l.organization_id = o.id
  JOIN organization_memberships om ON o.id = om.organization_id
  WHERE om.user_id = p_user_id
    AND om.status = 'active'
    AND l.is_active = true
    AND (p_organization_id IS NULL OR o.id = p_organization_id)
    AND (
      om.locations = '{}' OR -- Access to all locations
      l.id::text = ANY(om.locations) -- Access to specific locations
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check subscription limits
CREATE OR REPLACE FUNCTION check_subscription_limit(
  p_organization_id UUID,
  p_limit_type VARCHAR(50),
  p_current_usage INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  plan_limit INTEGER;
BEGIN
  -- Get the limit from current subscription plan
  SELECT 
    CASE p_limit_type
      WHEN 'locations' THEN sp.max_locations
      WHEN 'members' THEN sp.max_members
      WHEN 'trainers' THEN sp.max_trainers
      WHEN 'storage_gb' THEN sp.max_storage_gb
    END
  INTO plan_limit
  FROM subscriptions s
  JOIN subscription_plans sp ON s.plan_id = sp.id
  WHERE s.organization_id = p_organization_id
    AND s.status = 'active';
  
  -- NULL means unlimited
  IF plan_limit IS NULL THEN
    RETURN TRUE;
  END IF;
  
  RETURN p_current_usage < plan_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- USAGE EXAMPLES FOR GYM MANAGEMENT
-- ==================================================

/*
-- Create a gym organization
INSERT INTO organizations (name, slug, timezone, subscription_plan)
VALUES ('FitLife Gyms', 'fitlife-gyms', 'America/New_York', 'premium');

-- Add locations (gym branches)
INSERT INTO locations (organization_id, name, slug, city, max_capacity)
VALUES 
  ('org-uuid', 'Downtown Branch', 'downtown', 'New York', 200),
  ('org-uuid', 'Uptown Branch', 'uptown', 'New York', 150);

-- Add user to organization with role
INSERT INTO organization_memberships (organization_id, user_id, role, status)
VALUES ('org-uuid', 'user-uuid', 'manager', 'active');

-- Check if user has permission
SELECT user_has_permission('user-uuid', 'members.manage', 'org-uuid');

-- Check feature flag
SELECT is_feature_enabled('advanced_analytics', 'org-uuid');

-- Get user's accessible locations
SELECT * FROM get_user_locations('user-uuid', 'org-uuid');

-- Check subscription limits before adding new member
SELECT check_subscription_limit('org-uuid', 'members', 450);
*/
