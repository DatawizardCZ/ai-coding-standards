-- ==================================================
-- FUNCTION TEMPLATES
-- ==================================================
-- Common PostgreSQL/Supabase function patterns
-- Copy and modify as needed for your use case
-- ==================================================

-- ==================================================
-- 1. UTILITY FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Simple data transformation/calculation
CREATE OR REPLACE FUNCTION calculate_example(
  input_value DECIMAL,
  multiplier DECIMAL DEFAULT 1.0
)
RETURNS DECIMAL AS $$
BEGIN
  -- Input validation
  IF input_value IS NULL THEN
    RAISE EXCEPTION 'input_value cannot be null';
  END IF;
  
  IF multiplier <= 0 THEN
    RAISE EXCEPTION 'multiplier must be positive';
  END IF;
  
  -- Business logic
  RETURN input_value * multiplier;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add function comment
COMMENT ON FUNCTION calculate_example(DECIMAL, DECIMAL) IS 
'Calculates input_value * multiplier with validation';

-- ==================================================
-- 2. SECURE DATA ACCESS FUNCTION
-- ==================================================
-- Pattern: User-specific data retrieval with RLS
CREATE OR REPLACE FUNCTION get_user_data(
  p_user_id UUID DEFAULT auth.uid(),
  p_limit INTEGER DEFAULT 10,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  total_count BIGINT
) AS $$
BEGIN
  -- Security check
  IF p_user_id != auth.uid() AND NOT has_role('admin') THEN
    RAISE EXCEPTION 'Access denied: insufficient permissions';
  END IF;
  
  -- Input validation
  IF p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'Limit must be between 1 and 100';
  END IF;
  
  IF p_offset < 0 THEN
    RAISE EXCEPTION 'Offset must be non-negative';
  END IF;
  
  -- Query with pagination
  RETURN QUERY
  WITH data_with_count AS (
    SELECT 
      t.id,
      t.name,
      t.created_at,
      COUNT(*) OVER() as total_count
    FROM user_table t
    WHERE t.user_id = p_user_id
      AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC
    LIMIT p_limit OFFSET p_offset
  )
  SELECT 
    dwc.id,
    dwc.name,
    dwc.created_at,
    dwc.total_count
  FROM data_with_count dwc;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 3. TRIGGER FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Auto-update timestamps and audit trail
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  -- Update timestamp
  NEW.updated_at = now();
  
  -- Update user (if column exists)
  IF TG_TABLE_NAME = 'user_facing_table' THEN
    NEW.updated_by = auth.uid();
  END IF;
  
  -- Log the change (optional)
  INSERT INTO audit_log (
    table_name,
    record_id,
    operation,
    old_values,
    new_values,
    changed_by,
    changed_at
  ) VALUES (
    TG_TABLE_NAME,
    NEW.id,
    TG_OP,
    CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
    to_jsonb(NEW),
    auth.uid(),
    now()
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- 4. VALIDATION FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Data validation with business rules
CREATE OR REPLACE FUNCTION validate_business_rules()
RETURNS TRIGGER AS $$
BEGIN
  -- Email validation
  IF NEW.email IS NOT NULL AND NEW.email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format: %', NEW.email;
  END IF;
  
  -- Phone validation (basic)
  IF NEW.phone IS NOT NULL AND length(NEW.phone) < 10 THEN
    RAISE EXCEPTION 'Phone number too short: %', NEW.phone;
  END IF;
  
  -- Business rule: Cannot set status to 'completed' without required fields
  IF NEW.status = 'completed' AND (NEW.completion_date IS NULL OR NEW.completed_by IS NULL) THEN
    RAISE EXCEPTION 'Cannot mark as completed without completion_date and completed_by';
  END IF;
  
  -- Date validation
  IF NEW.start_date IS NOT NULL AND NEW.end_date IS NOT NULL AND NEW.start_date > NEW.end_date THEN
    RAISE EXCEPTION 'Start date cannot be after end date';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- 5. AGGREGATION FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Complex aggregation with filtering
CREATE OR REPLACE FUNCTION get_analytics_summary(
  p_user_id UUID DEFAULT auth.uid(),
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
  total_records INTEGER,
  active_records INTEGER,
  completion_rate DECIMAL,
  average_value DECIMAL,
  growth_percentage DECIMAL
) AS $$
DECLARE
  prev_period_start DATE;
  prev_period_end DATE;
  prev_total INTEGER;
BEGIN
  -- Input validation
  IF p_start_date > p_end_date THEN
    RAISE EXCEPTION 'Start date cannot be after end date';
  END IF;
  
  -- Calculate previous period for growth comparison
  prev_period_end := p_start_date - INTERVAL '1 day';
  prev_period_start := prev_period_end - (p_end_date - p_start_date);
  
  -- Get previous period total for growth calculation
  SELECT COUNT(*) INTO prev_total
  FROM user_records ur
  WHERE ur.user_id = p_user_id
    AND ur.created_at::date BETWEEN prev_period_start AND prev_period_end;
  
  -- Main query
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_records,
    COUNT(*) FILTER (WHERE status = 'active')::INTEGER as active_records,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND(COUNT(*) FILTER (WHERE status = 'completed') * 100.0 / COUNT(*), 2)
      ELSE 0
    END as completion_rate,
    ROUND(AVG(value), 2) as average_value,
    CASE 
      WHEN prev_total > 0 THEN 
        ROUND((COUNT(*)::DECIMAL - prev_total) * 100.0 / prev_total, 2)
      ELSE 0
    END as growth_percentage
  FROM user_records ur
  WHERE ur.user_id = p_user_id
    AND ur.created_at::date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 6. SEARCH FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Full-text search with ranking
CREATE OR REPLACE FUNCTION search_records(
  p_search_term TEXT,
  p_user_id UUID DEFAULT auth.uid(),
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE(
  id UUID,
  title TEXT,
  description TEXT,
  rank REAL,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  -- Input validation
  IF length(trim(p_search_term)) < 2 THEN
    RAISE EXCEPTION 'Search term must be at least 2 characters';
  END IF;
  
  -- Clean search term
  p_search_term := trim(p_search_term);
  
  RETURN QUERY
  SELECT 
    sr.id,
    sr.title,
    sr.description,
    ts_rank(
      to_tsvector('english', sr.title || ' ' || COALESCE(sr.description, '')),
      plainto_tsquery('english', p_search_term)
    ) as rank,
    sr.created_at
  FROM searchable_records sr
  WHERE sr.user_id = p_user_id
    AND sr.deleted_at IS NULL
    AND (
      sr.title ILIKE '%' || p_search_term || '%' OR
      sr.description ILIKE '%' || p_search_term || '%' OR
      to_tsvector('english', sr.title || ' ' || COALESCE(sr.description, '')) @@ plainto_tsquery('english', p_search_term)
    )
  ORDER BY rank DESC, sr.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 7. BATCH OPERATION FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Safe batch operations with error handling
CREATE OR REPLACE FUNCTION batch_update_status(
  p_record_ids UUID[],
  p_new_status TEXT,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS TABLE(
  updated_count INTEGER,
  failed_ids UUID[],
  error_messages TEXT[]
) AS $$
DECLARE
  record_id UUID;
  updated_records INTEGER := 0;
  failed_records UUID[] := '{}';
  error_msgs TEXT[] := '{}';
  current_error TEXT;
BEGIN
  -- Input validation
  IF array_length(p_record_ids, 1) IS NULL OR array_length(p_record_ids, 1) = 0 THEN
    RAISE EXCEPTION 'No record IDs provided';
  END IF;
  
  IF array_length(p_record_ids, 1) > 100 THEN
    RAISE EXCEPTION 'Cannot process more than 100 records at once';
  END IF;
  
  IF p_new_status NOT IN ('active', 'inactive', 'pending', 'completed') THEN
    RAISE EXCEPTION 'Invalid status: %', p_new_status;
  END IF;
  
  -- Process each record individually
  FOREACH record_id IN ARRAY p_record_ids
  LOOP
    BEGIN
      -- Attempt to update record
      UPDATE user_records 
      SET 
        status = p_new_status,
        updated_at = now(),
        updated_by = p_user_id
      WHERE id = record_id 
        AND user_id = p_user_id
        AND deleted_at IS NULL;
      
      -- Check if record was actually updated
      IF FOUND THEN
        updated_records := updated_records + 1;
      ELSE
        failed_records := array_append(failed_records, record_id);
        error_msgs := array_append(error_msgs, 'Record not found or access denied');
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      -- Capture error and continue
      failed_records := array_append(failed_records, record_id);
      error_msgs := array_append(error_msgs, SQLERRM);
    END;
  END LOOP;
  
  -- Return results
  RETURN QUERY
  SELECT 
    updated_records as updated_count,
    failed_records as failed_ids,
    error_msgs as error_messages;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 8. HELPER FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Utility functions for common operations
CREATE OR REPLACE FUNCTION has_role(role_name TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role = role_name
    AND deleted_at IS NULL
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION generate_slug(input_text TEXT)
RETURNS TEXT AS $
BEGIN
  -- Handle null input
  IF input_text IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Convert to lowercase, remove special chars, replace spaces with hyphens
  RETURN lower(
    regexp_replace(
      regexp_replace(
        regexp_replace(input_text, '[^\w\s-]', '', 'g'),
        '\s+', '-', 'g'
      ),
      '-+', '-', 'g'
    )
  );
END;
$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION format_currency(
  amount DECIMAL,
  currency_code TEXT DEFAULT 'USD'
)
RETURNS TEXT AS $
BEGIN
  IF amount IS NULL THEN
    RETURN NULL;
  END IF;
  
  RETURN currency_code || ' ' || to_char(amount, 'FM999,999,999.00');
END;
$ LANGUAGE plpgsql IMMUTABLE;

-- ==================================================
-- 9. SOFT DELETE FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Soft delete with cascade handling
CREATE OR REPLACE FUNCTION soft_delete_record(
  p_table_name TEXT,
  p_record_id UUID,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $
DECLARE
  query_text TEXT;
  affected_rows INTEGER;
BEGIN
  -- Validate table name (prevent SQL injection)
  IF p_table_name NOT IN ('users', 'orders', 'products', 'categories') THEN
    RAISE EXCEPTION 'Invalid table name: %', p_table_name;
  END IF;
  
  -- Build and execute dynamic query
  query_text := format('
    UPDATE %I 
    SET 
      deleted_at = now(),
      deleted_by = $2
    WHERE id = $1 
      AND deleted_at IS NULL
      AND (user_id = $2 OR EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE user_id = $2 AND role = ''admin''
      ))', p_table_name);
  
  EXECUTE query_text USING p_record_id, p_user_id;
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  
  RETURN affected_rows > 0;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 10. API RATE LIMITING FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Rate limiting for API endpoints
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_endpoint TEXT,
  p_max_requests INTEGER DEFAULT 100,
  p_window_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN AS $
DECLARE
  current_count INTEGER;
  window_start TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate window start
  window_start := date_trunc('minute', now()) - (p_window_minutes || ' minutes')::interval;
  
  -- Get current request count
  SELECT COALESCE(SUM(request_count), 0)
  INTO current_count
  FROM api_rate_limits
  WHERE user_id = auth.uid()
    AND endpoint = p_endpoint
    AND created_at > window_start;
  
  -- Check limit
  IF current_count >= p_max_requests THEN
    RETURN FALSE;
  END IF;
  
  -- Log this request
  INSERT INTO api_rate_limits (user_id, endpoint, request_count, created_at)
  VALUES (auth.uid(), p_endpoint, 1, now())
  ON CONFLICT (user_id, endpoint, date_trunc('minute', created_at))
  DO UPDATE SET request_count = api_rate_limits.request_count + 1;
  
  RETURN TRUE;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 11. NOTIFICATION FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Create notifications with templates
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_notification_type TEXT,
  p_data JSONB DEFAULT '{}'::jsonb,
  p_priority INTEGER DEFAULT 1
)
RETURNS UUID AS $
DECLARE
  notification_id UUID;
  template_content TEXT;
BEGIN
  -- Get notification template
  SELECT content INTO template_content
  FROM notification_templates
  WHERE type = p_notification_type AND is_active = true;
  
  IF template_content IS NULL THEN
    RAISE EXCEPTION 'No active template found for type: %', p_notification_type;
  END IF;
  
  -- Create notification
  INSERT INTO notifications (
    id,
    user_id,
    type,
    title,
    message,
    data,
    priority,
    is_read,
    created_at
  ) VALUES (
    gen_random_uuid(),
    p_user_id,
    p_notification_type,
    p_data->>'title',
    template_content,
    p_data,
    p_priority,
    false,
    now()
  ) RETURNING id INTO notification_id;
  
  -- Trigger real-time notification if high priority
  IF p_priority >= 3 THEN
    PERFORM pg_notify(
      'notification_' || p_user_id::text,
      json_build_object(
        'id', notification_id,
        'type', p_notification_type,
        'priority', p_priority
      )::text
    );
  END IF;
  
  RETURN notification_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- 12. DATA EXPORT FUNCTION TEMPLATE
-- ==================================================
-- Pattern: Secure data export with user permissions
CREATE OR REPLACE FUNCTION export_user_data(
  p_user_id UUID DEFAULT auth.uid(),
  p_format TEXT DEFAULT 'json',
  p_include_deleted BOOLEAN DEFAULT false
)
RETURNS TABLE(
  table_name TEXT,
  data JSONB
) AS $
DECLARE
  export_tables TEXT[] := ARRAY['user_profiles', 'user_orders', 'user_preferences'];
  table_name TEXT;
  query_text TEXT;
  table_data JSONB;
BEGIN
  -- Security check
  IF p_user_id != auth.uid() AND NOT has_role('admin') THEN
    RAISE EXCEPTION 'Access denied: can only export own data';
  END IF;
  
  -- Validate format
  IF p_format NOT IN ('json', 'csv') THEN
    RAISE EXCEPTION 'Invalid format: %. Supported: json, csv', p_format;
  END IF;
  
  -- Export each table
  FOREACH table_name IN ARRAY export_tables
  LOOP
    -- Build query based on table
    query_text := format('
      SELECT jsonb_agg(to_jsonb(t))
      FROM %I t
      WHERE user_id = $1
      %s',
      table_name,
      CASE WHEN NOT p_include_deleted THEN 'AND deleted_at IS NULL' ELSE '' END
    );
    
    -- Execute query
    EXECUTE query_text INTO table_data USING p_user_id;
    
    -- Return data if exists
    IF table_data IS NOT NULL THEN
      RETURN QUERY SELECT table_name, table_data;
    END IF;
  END LOOP;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================================================
-- FUNCTION USAGE EXAMPLES
-- ==================================================

/*
-- 1. Using utility functions
SELECT calculate_example(100.50, 1.15); -- Returns: 115.58
SELECT generate_slug('Hello World! Special Characters@#); -- Returns: hello-world-special-characters

-- 2. Using secure data access
SELECT * FROM get_user_data(); -- Gets current user's data
SELECT * FROM get_user_data('123e4567-e89b-12d3-a456-426614174000', 5, 0); -- Admin accessing specific user

-- 3. Using search function
SELECT * FROM search_records('important documents');

-- 4. Using analytics
SELECT * FROM get_analytics_summary();
SELECT * FROM get_analytics_summary(auth.uid(), '2024-01-01', '2024-01-31');

-- 5. Using batch operations
SELECT * FROM batch_update_status(
  ARRAY['123e4567-e89b-12d3-a456-426614174000', '987fcdeb-51d3-12e8-b456-426614174000'],
  'completed'
);

-- 6. Using rate limiting
SELECT check_rate_limit('api/search', 10, 5); -- 10 requests per 5 minutes

-- 7. Creating notifications
SELECT create_notification(
  auth.uid(),
  'order_completed',
  '{"title": "Order Complete", "order_id": "12345"}'::jsonb,
  2
);
*/

-- ==================================================
-- TRIGGER USAGE EXAMPLES
-- ==================================================

/*
-- Apply update timestamp trigger to tables
CREATE TRIGGER users_updated_at_trigger
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply validation trigger
CREATE TRIGGER users_validation_trigger
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION validate_business_rules();
*/

-- ==================================================
-- BEST PRACTICES FOR FUNCTIONS
-- ==================================================

/*
1. SECURITY:
   - Use SECURITY DEFINER sparingly and validate permissions
   - Sanitize all user inputs
   - Use parameterized queries to prevent SQL injection
   - Validate table/column names against allowlists

2. PERFORMANCE:
   - Keep functions focused and small
   - Use appropriate return types (TABLE vs single values)
   - Consider using IMMUTABLE for pure functions
   - Add proper indexes for function filters

3. ERROR HANDLING:
   - Validate inputs early
   - Provide meaningful error messages
   - Use transactions for multi-step operations
   - Log errors appropriately

4. MAINTAINABILITY:
   - Document function purpose and parameters
   - Use consistent naming patterns
   - Keep business logic in the application when possible
   - Version functions when making breaking changes

5. TESTING:
   - Test with various input combinations
   - Test error conditions
   - Test with different user roles/permissions
   - Performance test with realistic data volumes
*/
