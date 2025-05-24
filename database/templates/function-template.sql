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
RETURNS TEXT AS $$
