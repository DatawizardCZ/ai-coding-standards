# Supabase-Specific Patterns

*Platform-specific best practices for Supabase development*

---

## 🚀 Quick Start

### Essential Setup
1. **Enable RLS** on all user-facing tables
2. **Create auth policies** for data access
3. **Set up profile creation** trigger
4. **Configure realtime** for live updates
5. **Use edge functions** for complex operations

---

## 🔐 Row Level Security (RLS)

### Basic Patterns

#### 1. User Isolation Pattern
```sql
-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Basic user isolation
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);
```

#### 2. Role-Based Access Pattern
```sql
-- Admin access to all records
CREATE POLICY "Admins can view all users" ON user_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Role-based multi-access
CREATE POLICY "Staff can view assigned records" ON orders
  FOR SELECT USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role IN ('admin', 'manager')
    )
  );
```

#### 3. Ownership with Delegation Pattern
```sql
-- Owner or assigned user can access
CREATE POLICY "Owner or assigned can access" ON projects
  FOR ALL USING (
    created_by = auth.uid() OR 
    assigned_to = auth.uid()
  );
```

#### 4. Time-Based Access Pattern
```sql
-- Can only edit recent records
CREATE POLICY "Users can edit recent posts" ON posts
  FOR UPDATE USING (
    user_id = auth.uid() 
    AND created_at > now() - interval '24 hours'
  );

-- Access to active records only
CREATE POLICY "Access to active records" ON subscriptions
  FOR SELECT USING (
    user_id = auth.uid() 
    AND expires_at > now()
  );
```

### Advanced RLS Patterns

#### 1. Multi-Tenant Pattern
```sql
-- Organization-based isolation
CREATE POLICY "Organization isolation" ON projects
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_organizations uo
      WHERE uo.user_id = auth.uid() 
      AND uo.organization_id = projects.organization_id
    )
  );
```

#### 2. Hierarchical Access Pattern
```sql
-- Manager can see team members' data
CREATE POLICY "Hierarchical access" ON tasks
  FOR SELECT USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN profiles p ON p.user_id = auth.uid()
      WHERE tm.manager_id = p.id 
      AND tm.member_id = tasks.assigned_to
    )
  );
```

#### 3. Status-Based Access Pattern
```sql
-- Different access based on record status
CREATE POLICY "Status-based access" ON documents
  FOR UPDATE USING (
    CASE 
      WHEN status = 'published' THEN 
        EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
      WHEN status = 'draft' THEN 
        created_by = auth.uid()
      ELSE 
        created_by = auth.uid() OR assigned_to = auth.uid()
    END
  );
```

---

## 🔑 Authentication Integration

### Profile Management

#### 1. Auto Profile Creation
```sql
-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (
    user_id, 
    email, 
    first_name, 
    last_name,
    role,
    created_at
  ) VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    NEW.created_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

#### 2. Profile Updates
```sql
-- Function to sync profile changes
CREATE OR REPLACE FUNCTION sync_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Update email if changed
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE profiles 
    SET email = NEW.email, updated_at = now()
    WHERE user_id = NEW.id;
  END IF;
  
  -- Update metadata if changed
  IF NEW.raw_user_meta_data IS DISTINCT FROM OLD.raw_user_meta_data THEN
    UPDATE profiles 
    SET 
      first_name = NEW.raw_user_meta_data->>'first_name',
      last_name = NEW.raw_user_meta_data->>'last_name',
      updated_at = now()
    WHERE user_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION sync_user_profile();
```

### Helper Functions

#### 1. Get Current User Profile
```sql
CREATE OR REPLACE FUNCTION get_current_user_profile()
RETURNS profiles AS $$
  SELECT * FROM profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;
```

#### 2. Check User Role
```sql
CREATE OR REPLACE FUNCTION has_role(role_name TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = auth.uid() 
    AND role = role_name
  );
$$ LANGUAGE sql SECURITY DEFINER;
```

#### 3. Get User Organization
```sql
CREATE OR REPLACE FUNCTION get_user_organization()
RETURNS UUID AS $$
  SELECT organization_id FROM profiles WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;
```

---

## ⚡ Realtime Features

### Enable Realtime

#### 1. Basic Table Subscription
```sql
-- Enable realtime for specific tables
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

#### 2. Filtered Realtime
```sql
-- Create view for filtered realtime updates
CREATE VIEW user_notifications_realtime AS
SELECT * FROM notifications 
WHERE user_id = auth.uid();

-- Enable realtime on view
ALTER PUBLICATION supabase_realtime ADD TABLE user_notifications_realtime;
```

#### 3. Dashboard Stats Realtime
```sql
-- Materialized view for dashboard (refresh periodically)
CREATE MATERIALIZED VIEW dashboard_stats AS
SELECT 
  COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE created_at::date = CURRENT_DATE) as today_count,
  SUM(amount) FILTER (WHERE created_at::date = CURRENT_DATE) as today_total
FROM orders;

-- Function to refresh stats
CREATE OR REPLACE FUNCTION refresh_dashboard_stats()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW dashboard_stats;
END;
$$ LANGUAGE plpgsql;

-- Enable realtime (will update when refreshed)
ALTER PUBLICATION supabase_realtime ADD TABLE dashboard_stats;
```

### Frontend Integration Examples

#### 1. React Hook for Realtime
```typescript
// Custom hook for realtime subscriptions
function useRealtimeSubscription<T>(
  table: string,
  filter?: string
) {
  const [data, setData] = useState<T[]>([]);
  
  useEffect(() => {
    const subscription = supabase
      .channel(`${table}_changes`)
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: table,
          filter: filter 
        },
        (payload) => {
          // Handle real-time updates
          console.log('Change received!', payload);
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [table, filter]);

  return data;
}
```

---

## 🔧 Edge Functions

### Common Patterns

#### 1. Email Notifications
```typescript
// Edge function for sending emails
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { record, old_record, type } = await req.json();
  
  // Send email based on database changes
  if (type === 'INSERT' && record.table === 'orders') {
    await sendOrderConfirmationEmail(record.email);
  }
  
  return new Response('OK');
});
```

#### 2. Complex Business Logic
```typescript
// Edge function for data processing
serve(async (req) => {
  const { record_id } = await req.json();
  
  // Complex processing logic
  const result = await processComplexData(record_id);
  
  // Update record with result
  await supabase
    .from('processing_results')
    .insert({ 
      record_id, 
      result, 
      processed_at: new Date() 
    });
    
  return new Response(JSON.stringify({ result }));
});
```

#### 3. Third-Party Integrations
```typescript
// Edge function for external API sync
serve(async (req) => {
  const { data } = await req.json();
  
  // Sync with external service
  const apiResponse = await fetch('https://api.external.com/webhook', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${API_KEY}` },
    body: JSON.stringify(data)
  });
  
  return new Response('Synced');
});
```

---

## 🗄️ Storage Patterns

### File Organization
```sql
-- File uploads table
CREATE TABLE file_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  bucket_name TEXT DEFAULT 'uploads',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for file access
CREATE POLICY "Users can upload files" ON file_uploads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own files" ON file_uploads
  FOR SELECT USING (auth.uid() = user_id);
```

### Storage Bucket Policies
```sql
-- Bucket policy for user uploads
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'uploads' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Public read access for public files
CREATE POLICY "Public can view public files"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-files');
```

---

## 🔍 Database Functions

### Supabase-Optimized Functions

#### 1. Pagination with Count
```sql
CREATE OR REPLACE FUNCTION get_records_paginated(
  table_name TEXT,
  page_size INTEGER DEFAULT 10,
  page_offset INTEGER DEFAULT 0,
  filter_column TEXT DEFAULT NULL,
  filter_value TEXT DEFAULT NULL
)
RETURNS TABLE(
  total_count BIGINT,
  records JSONB
) AS $$
DECLARE
  query_text TEXT;
BEGIN
  -- Build dynamic query (be careful with SQL injection)
  query_text := format('
    WITH record_data AS (
      SELECT r.*, COUNT(*) OVER() as total
      FROM %I r
      WHERE ($3 IS NULL OR %I = $4)
      ORDER BY r.created_at DESC
      LIMIT $1 OFFSET $2
    )
    SELECT 
      COALESCE(MAX(rd.total), 0) as total_count,
      COALESCE(jsonb_agg(to_jsonb(rd) - ''total''), ''[]''::jsonb) as records
    FROM record_data rd', 
    table_name, COALESCE(filter_column, 'id')
  );
  
  RETURN QUERY EXECUTE query_text USING page_size, page_offset, filter_column, filter_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 2. Search with RLS
```sql
CREATE OR REPLACE FUNCTION search_records(
  table_name TEXT,
  search_term TEXT,
  search_columns TEXT[] DEFAULT ARRAY['name', 'description']
)
RETURNS TABLE(
  id UUID,
  data JSONB,
  rank REAL
) AS $$
DECLARE
  query_text TEXT;
  search_condition TEXT;
BEGIN
  -- Build search condition
  SELECT string_agg(format('%I ILIKE ''%%'' || $2 || ''%%''', col), ' OR ')
  INTO search_condition
  FROM unnest(search_columns) AS col;
  
  -- Build query
  query_text := format('
    SELECT 
      r.id,
      to_jsonb(r) as data,
      1.0 as rank
    FROM %I r
    WHERE %s
    ORDER BY r.created_at DESC',
    table_name, search_condition
  );
  
  RETURN QUERY EXECUTE query_text USING table_name, search_term;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📊 Analytics & Reporting

### Secure Analytics Functions

#### 1. User-Specific Metrics
```sql
CREATE OR REPLACE FUNCTION get_user_analytics(
  user_id UUID DEFAULT auth.uid(),
  period_days INTEGER DEFAULT 30
)
RETURNS TABLE(
  total_records INTEGER,
  recent_records INTEGER,
  growth_rate DECIMAL
) AS $$
BEGIN
  -- Verify user can access these metrics
  IF NOT (user_id = auth.uid() OR has_role('admin')) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_records,
    COUNT(*) FILTER (WHERE created_at >= now() - (period_days || ' days')::interval)::INTEGER as recent_records,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND(COUNT(*) FILTER (WHERE created_at >= now() - (period_days || ' days')::interval) * 100.0 / COUNT(*), 2)
      ELSE 0
    END as growth_rate
  FROM user_records
  WHERE owner_id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 2. Aggregated Dashboard Data
```sql
CREATE OR REPLACE FUNCTION get_dashboard_summary()
RETURNS TABLE(
  metric_name TEXT,
  metric_value INTEGER,
  metric_change DECIMAL
) AS $
BEGIN
  RETURN QUERY
  WITH current_period AS (
    SELECT 
      'total_users' as metric,
      COUNT(*)::INTEGER as current_value,
      COUNT(*) FILTER (WHERE created_at >= now() - interval '7 days')::INTEGER as recent_value
    FROM profiles
    WHERE (auth.uid() = user_id OR has_role('admin'))
    
    UNION ALL
    
    SELECT 
      'active_sessions' as metric,
      COUNT(*)::INTEGER as current_value,
      COUNT(*) FILTER (WHERE created_at >= now() - interval '1 day')::INTEGER as recent_value
    FROM user_sessions
    WHERE expires_at > now()
  )
  SELECT 
    cp.metric as metric_name,
    cp.current_value as metric_value,
    CASE 
      WHEN cp.current_value > 0 THEN 
        ROUND((cp.recent_value * 100.0 / cp.current_value), 2)
      ELSE 0
    END as metric_change
  FROM current_period cp;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔒 Security Best Practices

### 1. Function Security
```sql
-- Always use SECURITY DEFINER for functions that need elevated privileges
CREATE OR REPLACE FUNCTION admin_only_function()
RETURNS TABLE(sensitive_data TEXT)
SECURITY DEFINER
AS $
BEGIN
  -- Verify admin role
  IF NOT has_role('admin') THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;
  
  -- Function logic here
  RETURN QUERY SELECT 'sensitive_information'::TEXT;
END;
$ LANGUAGE plpgsql;
```

### 2. Data Sanitization
```sql
-- Function to sanitize user input
CREATE OR REPLACE FUNCTION sanitize_search_term(input_text TEXT)
RETURNS TEXT AS $
BEGIN
  -- Remove potentially dangerous characters
  RETURN regexp_replace(
    regexp_replace(input_text, '[^\w\s-]', '', 'g'),
    '\s+', ' ', 'g'
  );
END;
$ LANGUAGE plpgsql IMMUTABLE;
```

### 3. Rate Limiting Pattern
```sql
-- Table to track API usage
CREATE TABLE api_rate_limits (
  user_id UUID REFERENCES profiles(id),
  endpoint TEXT NOT NULL,
  request_count INTEGER DEFAULT 1,
  window_start TIMESTAMP WITH TIME ZONE DEFAULT now(),
  PRIMARY KEY (user_id, endpoint, window_start)
);

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
  endpoint_name TEXT,
  max_requests INTEGER DEFAULT 100,
  window_minutes INTEGER DEFAULT 60
)
RETURNS BOOLEAN AS $
DECLARE
  current_count INTEGER;
BEGIN
  -- Get current request count for this window
  SELECT COALESCE(SUM(request_count), 0)
  INTO current_count
  FROM api_rate_limits
  WHERE user_id = auth.uid()
    AND endpoint = endpoint_name
    AND window_start > now() - (window_minutes || ' minutes')::interval;
  
  -- Check if limit exceeded
  IF current_count >= max_requests THEN
    RETURN false;
  END IF;
  
  -- Increment counter
  INSERT INTO api_rate_limits (user_id, endpoint, request_count, window_start)
  VALUES (auth.uid(), endpoint_name, 1, date_trunc('minute', now()))
  ON CONFLICT (user_id, endpoint, window_start)
  DO UPDATE SET request_count = api_rate_limits.request_count + 1;
  
  RETURN true;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🚀 Performance Optimization

### 1. Efficient RLS Policies
```sql
-- Optimize RLS with indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_profiles_role ON profiles(role);

-- Efficient policy using indexed columns
CREATE POLICY "Efficient user access" ON orders
  FOR ALL USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );
```

### 2. Optimized Queries
```sql
-- Use covering indexes for common queries
CREATE INDEX idx_orders_covering ON orders(user_id, status) 
INCLUDE (created_at, total_amount);

-- Optimize with partial indexes
CREATE INDEX idx_active_orders ON orders(user_id, created_at)
WHERE status IN ('pending', 'processing');
```

### 3. Batch Operations
```sql
-- Efficient batch insert function
CREATE OR REPLACE FUNCTION batch_insert_records(
  record_data JSONB[]
)
RETURNS INTEGER AS $
DECLARE
  inserted_count INTEGER;
BEGIN
  -- Verify permissions
  IF NOT has_role('admin') THEN
    RAISE EXCEPTION 'Access denied';
  END IF;
  
  -- Batch insert with unnest
  WITH inserted AS (
    INSERT INTO target_table (data, user_id, created_at)
    SELECT 
      record,
      auth.uid(),
      now()
    FROM unnest(record_data) AS record
    RETURNING id
  )
  SELECT COUNT(*) INTO inserted_count FROM inserted;
  
  RETURN inserted_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔄 Common Integration Patterns

### 1. Webhook Handler
```sql
-- Table to log webhook events
CREATE TABLE webhook_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT false,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Function to process webhooks
CREATE OR REPLACE FUNCTION process_webhook(
  event_type TEXT,
  payload JSONB
)
RETURNS BOOLEAN AS $
BEGIN
  -- Log the webhook
  INSERT INTO webhook_logs (event_type, payload)
  VALUES (event_type, payload);
  
  -- Process based on event type
  CASE event_type
    WHEN 'user.created' THEN
      PERFORM handle_user_created(payload);
    WHEN 'payment.completed' THEN
      PERFORM handle_payment_completed(payload);
    ELSE
      RAISE NOTICE 'Unknown event type: %', event_type;
  END CASE;
  
  -- Mark as processed
  UPDATE webhook_logs 
  SET processed = true 
  WHERE event_type = process_webhook.event_type 
    AND payload = process_webhook.payload;
  
  RETURN true;
EXCEPTION WHEN OTHERS THEN
  -- Log error
  UPDATE webhook_logs 
  SET error_message = SQLERRM
  WHERE event_type = process_webhook.event_type 
    AND payload = process_webhook.payload;
  
  RETURN false;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. Data Sync Pattern
```sql
-- Sync status tracking
CREATE TABLE sync_status (
  sync_type TEXT PRIMARY KEY,
  last_sync_at TIMESTAMP WITH TIME ZONE,
  sync_in_progress BOOLEAN DEFAULT false,
  error_count INTEGER DEFAULT 0
);

-- Function for safe data sync
CREATE OR REPLACE FUNCTION sync_external_data(
  sync_type TEXT
)
RETURNS BOOLEAN AS $
DECLARE
  is_running BOOLEAN;
BEGIN
  -- Check if sync is already running
  SELECT sync_in_progress INTO is_running
  FROM sync_status 
  WHERE sync_type = sync_external_data.sync_type;
  
  IF is_running THEN
    RAISE NOTICE 'Sync already in progress for type: %', sync_type;
    RETURN false;
  END IF;
  
  -- Mark sync as started
  INSERT INTO sync_status (sync_type, sync_in_progress, last_sync_at)
  VALUES (sync_type, true, now())
  ON CONFLICT (sync_type) 
  DO UPDATE SET sync_in_progress = true, last_sync_at = now();
  
  -- Perform sync logic here
  -- ... sync operations ...
  
  -- Mark sync as completed
  UPDATE sync_status 
  SET sync_in_progress = false, error_count = 0
  WHERE sync_type = sync_external_data.sync_type;
  
  RETURN true;
EXCEPTION WHEN OTHERS THEN
  -- Handle errors
  UPDATE sync_status 
  SET sync_in_progress = false, error_count = error_count + 1
  WHERE sync_type = sync_external_data.sync_type;
  
  RAISE;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📱 Client-Side Integration

### 1. Type-Safe Database Calls
```typescript
// Generate types from Supabase
export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          user_id: string;
          first_name: string | null;
          last_name: string | null;
          role: string;
          created_at: string;
        };
        Insert: {
          user_id: string;
          first_name?: string;
          last_name?: string;
          role?: string;
        };
        Update: {
          first_name?: string;
          last_name?: string;
          role?: string;
        };
      };
    };
  };
};

// Type-safe client
const supabase = createClient<Database>(url, key);
```

### 2. Error Handling Patterns
```typescript
// Standardized error handling
export async function handleSupabaseError<T>(
  operation: () => Promise<{ data: T | null; error: any }>
): Promise<T> {
  try {
    const { data, error } = await operation();
    
    if (error) {
      // Log error for monitoring
      console.error('Supabase error:', error);
      
      // Handle specific error types
      if (error.code === 'PGRST116') {
        throw new Error('Access denied');
      }
      
      throw new Error(error.message || 'Database operation failed');
    }
    
    if (!data) {
      throw new Error('No data returned');
    }
    
    return data;
  } catch (error) {
    throw error instanceof Error ? error : new Error('Unknown error');
  }
}
```

---

## 🔗 Quick Reference

### Essential Commands
```sql
-- Enable RLS
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Create basic policy
CREATE POLICY "policy_name" ON table_name
  FOR SELECT USING (user_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE table_name;

-- Create secure function
CREATE OR REPLACE FUNCTION function_name()
RETURNS return_type
SECURITY DEFINER
AS $ ... $ LANGUAGE plpgsql;
```

### Common Gotchas
- Always enable RLS on user-facing tables
- Use `SECURITY DEFINER` carefully - validate permissions
- Test RLS policies thoroughly with different user roles
- Monitor realtime subscriptions for performance impact
- Use indexes to optimize RLS policy conditions

---

## 📋 Checklist for New Supabase Projects

- [ ] Set up authentication with profile creation trigger
- [ ] Enable RLS on all user-facing tables
- [ ] Create role-based access policies
- [ ] Set up realtime for necessary tables
- [ ] Configure storage buckets with proper policies
- [ ] Create helper functions for common operations
- [ ] Set up monitoring and error tracking
- [ ] Test all policies with different user roles

---

*For more Supabase-specific guidance, check the [official documentation](https://supabase.com/docs) and [community examples](https://github.com/supabase/supabase/tree/master/examples).*
