-- ==================================================
-- COMMON DATABASE PATTERNS EXAMPLES
-- ==================================================
-- Real-world patterns that appear in most applications
-- Copy and adapt these patterns for your specific needs
-- ==================================================

-- ==================================================
-- 1. USER MANAGEMENT PATTERN
-- ==================================================
-- Foundation for any application with users

-- Core users table (minimal Supabase auth integration)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  last_login_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Extended user profiles
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  display_name VARCHAR(200),
  avatar_url TEXT,
  bio TEXT,
  phone VARCHAR(20),
  date_of_birth DATE,
  timezone VARCHAR(50) DEFAULT 'UTC',
  language VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- User roles and permissions
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  permissions JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id INTEGER NOT NULL REFERENCES roles(id),
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user_id, role_id)
);

-- User sessions (optional - for custom session management)
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for user management
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);

-- RLS policies for user management
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (user_id = auth.uid());

-- ==================================================
-- 2. HIERARCHICAL DATA PATTERN
-- ==================================================
-- For categories, comments, organizational structures

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  sort_order INTEGER DEFAULT 0,
  level INTEGER DEFAULT 0,
  path TEXT, -- Materialized path: /parent/child/grandchild/
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Trigger to maintain level and path
CREATE OR REPLACE FUNCTION update_category_hierarchy()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.level := 0;
    NEW.path := '/' || NEW.slug || '/';
  ELSE
    SELECT level + 1, path || NEW.slug || '/'
    INTO NEW.level, NEW.path
    FROM categories 
    WHERE id = NEW.parent_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER category_hierarchy_trigger
  BEFORE INSERT OR UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_category_hierarchy();

-- Indexes for hierarchical queries
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_categories_path ON categories(path);
CREATE INDEX idx_categories_level ON categories(level);
CREATE INDEX idx_categories_slug ON categories(slug);

-- ==================================================
-- 3. TAGGING SYSTEM PATTERN
-- ==================================================
-- Flexible tagging for any content

CREATE TABLE tags (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  color VARCHAR(7), -- Hex color code
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Many-to-many relationship table
CREATE TABLE content_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_type VARCHAR(50) NOT NULL, -- 'post', 'product', 'user', etc.
  content_id UUID NOT NULL,
  tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  tagged_by UUID REFERENCES users(id),
  tagged_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(content_type, content_id, tag_id)
);

-- Function to update tag usage count
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tag_usage_trigger
  AFTER INSERT OR DELETE ON content_tags
  FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

-- Indexes for tagging
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_tags_usage ON tags(usage_count DESC);
CREATE INDEX idx_content_tags_content ON content_tags(content_type, content_id);
CREATE INDEX idx_content_tags_tag ON content_tags(tag_id);

-- ==================================================
-- 4. AUDIT LOG PATTERN
-- ==================================================
-- Track all changes for compliance and debugging

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[], -- Array of changed field names
  user_id UUID REFERENCES users(id),
  session_id UUID,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
  old_data JSONB;
  new_data JSONB;
  changed_fields TEXT[] := '{}';
  field_name TEXT;
BEGIN
  -- Prepare data
  IF TG_OP = 'DELETE' THEN
    old_data := to_jsonb(OLD);
    new_data := NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    old_data := to_jsonb(OLD);
    new_data := to_jsonb(NEW);
    
    -- Find changed fields
    FOR field_name IN SELECT key FROM jsonb_each(new_data) LOOP
      IF old_data->>field_name IS DISTINCT FROM new_data->>field_name THEN
        changed_fields := array_append(changed_fields, field_name);
      END IF;
    END LOOP;
  ELSE -- INSERT
    old_data := NULL;
    new_data := to_jsonb(NEW);
  END IF;
  
  -- Insert audit record
  INSERT INTO audit_logs (
    table_name, record_id, operation, old_values, new_values, 
    changed_fields, user_id, created_at
  ) VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    old_data,
    new_data,
    changed_fields,
    auth.uid(),
    now()
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Indexes for audit logs
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_operation ON audit_logs(operation);

-- ==================================================
-- 5. NOTIFICATION SYSTEM PATTERN
-- ==================================================
-- In-app notifications with templates

CREATE TABLE notification_templates (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  subject_template TEXT NOT NULL,
  body_template TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'email', 'push', 'in_app'
  variables JSONB DEFAULT '[]', -- Expected template variables
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  template_id INTEGER REFERENCES notification_templates(id),
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSONB DEFAULT '{}', -- Additional structured data
  priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE
);

-- Notification preferences
CREATE TABLE user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notification_type VARCHAR(50) NOT NULL,
  email_enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  in_app_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id, notification_type)
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at);

-- RLS for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- ==================================================
-- 6. FILE UPLOAD PATTERN
-- ==================================================
-- Track uploaded files with metadata

CREATE TABLE file_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  original_filename VARCHAR(255) NOT NULL,
  stored_filename VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  file_hash VARCHAR(64), -- SHA-256 hash for deduplication
  bucket_name VARCHAR(100) DEFAULT 'uploads',
  is_public BOOLEAN DEFAULT false,
  download_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}', -- Image dimensions, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- File access logs
CREATE TABLE file_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_id UUID NOT NULL REFERENCES file_uploads(id),
  accessed_by UUID REFERENCES users(id),
  access_type VARCHAR(20) NOT NULL, -- 'view', 'download', 'delete'
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Indexes for file management
CREATE INDEX idx_file_uploads_user_id ON file_uploads(user_id);
CREATE INDEX idx_file_uploads_hash ON file_uploads(file_hash);
CREATE INDEX idx_file_uploads_mime_type ON file_uploads(mime_type);
CREATE INDEX idx_file_uploads_created_at ON file_uploads(created_at);
CREATE INDEX idx_file_access_logs_file_id ON file_access_logs(file_id);

-- RLS for file uploads
ALTER TABLE file_uploads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own files" ON file_uploads FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Public files viewable" ON file_uploads FOR SELECT USING (is_public = true);

-- ==================================================
-- 7. ACTIVITY FEED PATTERN
-- ==================================================
-- Track user activities for feeds and analytics

CREATE TABLE activity_types (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  is_public BOOLEAN DEFAULT false, -- Show in public feeds
  points INTEGER DEFAULT 0, -- Gamification points
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type_id INTEGER NOT NULL REFERENCES activity_types(id),
  target_type VARCHAR(50), -- 'post', 'comment', 'user', etc.
  target_id UUID,
  data JSONB DEFAULT '{}', -- Flexible activity data
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Activity aggregations for performance
CREATE TABLE daily_activity_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  date DATE NOT NULL,
  activity_type_id INTEGER NOT NULL REFERENCES activity_types(id),
  count INTEGER DEFAULT 0,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id, date, activity_type_id)
);

-- Indexes for activity feeds
CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_created_at ON activities(created_at);
CREATE INDEX idx_activities_type ON activities(activity_type_id);
CREATE INDEX idx_activities_target ON activities(target_type, target_id);
CREATE INDEX idx_activities_public ON activities(is_public, created_at);

-- ==================================================
-- 8. SETTINGS AND PREFERENCES PATTERN
-- ==================================================
-- Flexible user and application settings

CREATE TABLE setting_definitions (
  id SERIAL PRIMARY KEY,
  key VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  data_type VARCHAR(20) NOT NULL CHECK (data_type IN ('string', 'integer', 'boolean', 'json')),
  default_value TEXT,
  validation_rules JSONB, -- JSON schema or validation rules
  is_user_configurable BOOLEAN DEFAULT true,
  category VARCHAR(100),
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  setting_key VARCHAR(100) NOT NULL REFERENCES setting_definitions(key),
  value TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id, setting_key)
);

CREATE TABLE application_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key VARCHAR(100) NOT NULL REFERENCES setting_definitions(key),
  value TEXT NOT NULL,
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(setting_key)
);

-- Function to get user setting with fallback
CREATE OR REPLACE FUNCTION get_user_setting(
  p_user_id UUID,
  p_setting_key VARCHAR(100)
)
RETURNS TEXT AS $$
DECLARE
  setting_value TEXT;
  default_value TEXT;
BEGIN
  -- Try to get user setting
  SELECT value INTO setting_value
  FROM user_settings
  WHERE user_id = p_user_id AND setting_key = p_setting_key;
  
  -- Fall back to default if not found
  IF setting_value IS NULL THEN
    SELECT sd.default_value INTO default_value
    FROM setting_definitions sd
    WHERE sd.key = p_setting_key;
    
    RETURN default_value;
  END IF;
  
  RETURN setting_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Indexes for settings
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX idx_user_settings_key ON user_settings(setting_key);

-- ==================================================
-- 9. SEARCH AND FILTERING PATTERN
-- ==================================================
-- Full-text search with filters

-- Add search vectors to content tables
ALTER TABLE content_table ADD COLUMN search_vector tsvector;

-- Function to update search vector
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := 
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to maintain search vector
CREATE TRIGGER content_search_vector_trigger
  BEFORE INSERT OR UPDATE ON content_table
  FOR EACH ROW EXECUTE FUNCTION update_search_vector();

-- GIN index for full-text search
CREATE INDEX idx_content_search_vector ON content_table USING GIN(search_vector);

-- Saved searches
CREATE TABLE saved_searches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  search_query TEXT NOT NULL,
  filters JSONB DEFAULT '{}',
  sort_order VARCHAR(100),
  is_alert BOOLEAN DEFAULT false, -- Notify on new results
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  last_executed_at TIMESTAMP WITH TIME ZONE
);

-- ==================================================
-- 10. RATE LIMITING PATTERN
-- ==================================================
-- API rate limiting and usage tracking

CREATE TABLE api_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  ip_address INET,
  endpoint VARCHAR(255) NOT NULL,
  request_count INTEGER DEFAULT 1,
  window_start TIMESTAMP WITH TIME ZONE DEFAULT date_trunc('minute', now()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id, endpoint, window_start),
  UNIQUE(ip_address, endpoint, window_start)
);

-- Function to check and record rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_endpoint VARCHAR(255),
  p_max_requests INTEGER DEFAULT 60,
  p_window_minutes INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
  current_count INTEGER;
  window_start TIMESTAMP WITH TIME ZONE;
BEGIN
  window_start := date_trunc('minute', now()) - (p_window_minutes - 1 || ' minutes')::interval;
  
  -- Get current count
  SELECT COALESCE(SUM(request_count), 0) INTO current_count
  FROM api_rate_limits
  WHERE (user_id = auth.uid() OR ip_address = inet_client_addr())
    AND endpoint = p_endpoint
    AND window_start >= window_start;
  
  -- Check limit
  IF current_count >= p_max_requests THEN
    RETURN FALSE;
  END IF;
  
  -- Record this request
  INSERT INTO api_rate_limits (user_id, ip_address, endpoint, request_count, window_start)
  VALUES (auth.uid(), inet_client_addr(), p_endpoint, 1, date_trunc('minute', now()))
  ON CONFLICT (user_id, endpoint, window_start) 
  DO UPDATE SET request_count = api_rate_limits.request_count + 1;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup old rate limit records
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS void AS $$
BEGIN
  DELETE FROM api_rate_limits 
  WHERE created_at < now() - interval '24 hours';
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- HELPER FUNCTIONS FOR COMMON PATTERNS
-- ==================================================

-- Generate unique slug
CREATE OR REPLACE FUNCTION generate_unique_slug(
  base_text TEXT,
  table_name TEXT,
  column_name TEXT DEFAULT 'slug'
)
RETURNS TEXT AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
  exists_check BOOLEAN;
BEGIN
  -- Generate base slug
  base_slug := lower(regexp_replace(regexp_replace(base_text, '[^\w\s-]', '', 'g'), '\s+', '-', 'g'));
  final_slug := base_slug;
  
  -- Check for uniqueness and increment if needed
  LOOP
    EXECUTE format('SELECT EXISTS(SELECT 1 FROM %I WHERE %I = $1)', table_name, column_name)
    USING final_slug
    INTO exists_check;
    
    EXIT WHEN NOT exists_check;
    
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$ LANGUAGE plpgsql;

-- Soft delete function
CREATE OR REPLACE FUNCTION soft_delete(
  table_name TEXT,
  record_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  query_text TEXT;
  affected_rows INTEGER;
BEGIN
  query_text := format('UPDATE %I SET deleted_at = now(), updated_at = now() WHERE id = $1 AND deleted_at IS NULL', table_name);
  EXECUTE query_text USING record_id;
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  
  RETURN affected_rows > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- USAGE EXAMPLES
-- ==================================================

/*
-- Apply audit trigger to a table
CREATE TRIGGER users_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- Create a notification
SELECT create_notification(
  'user-id-here',
  'welcome',
  '{"user_name": "John Doe"}'::jsonb,
  2
);

-- Check rate limit before API operation
SELECT check_rate_limit('/api/search', 10, 1); -- 10 requests per minute

-- Generate unique slug
SELECT generate_unique_slug('My Great Article', 'articles', 'slug');

-- Get user setting with fallback
SELECT get_user_setting('user-id', 'theme');
*/
