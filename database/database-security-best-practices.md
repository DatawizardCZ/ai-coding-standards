# Database Security Best Practices

*Comprehensive security guidelines for production database systems*

---

## 🎯 Security Overview

Database security is multi-layered protection against unauthorized access, data breaches, and compliance violations. This guide covers security practices from database design to operational procedures.

### **Security Principles**
- **Principle of Least Privilege** - Users get minimum required access
- **Defense in Depth** - Multiple security layers
- **Data Classification** - Protect based on sensitivity level
- **Audit Everything** - Complete activity tracking
- **Fail Securely** - Default to deny access

---

## 🔐 Authentication & Access Control

### 1. User Authentication

#### **Strong Authentication Policies**
```sql
-- Enforce strong password policies
ALTER ROLE username PASSWORD 'ComplexP@ssw0rd123!';

-- Set password expiration
ALTER ROLE username VALID UNTIL '2024-12-31';

-- Require password changes
ALTER ROLE username PASSWORD 'NewP@ssw0rd' VALID UNTIL '2024-06-30';
```

#### **Multi-Factor Authentication (MFA)**
```sql
-- For Supabase: Enable MFA in dashboard settings
-- For custom auth: Implement TOTP or SMS verification

-- Store MFA backup codes securely
CREATE TABLE user_mfa_backup_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  code_hash VARCHAR(255) NOT NULL, -- Hashed backup code
  used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT now() + INTERVAL '1 year'
);
```

#### **Session Management**
```sql
-- Secure session tracking
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  session_token VARCHAR(255) UNIQUE NOT NULL,
  ip_address INET NOT NULL,
  user_agent TEXT,
  is_mobile BOOLEAN DEFAULT false,
  location_country VARCHAR(2),
  location_city VARCHAR(100),
  
  -- Security tracking
  login_method VARCHAR(50), -- 'password', 'oauth', 'sso'
  risk_score INTEGER DEFAULT 0, -- 0-100 risk assessment
  requires_verification BOOLEAN DEFAULT false,
  
  -- Lifecycle
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT now() + INTERVAL '7 days',
  revoked_at TIMESTAMP WITH TIME ZONE,
  revoked_reason VARCHAR(100)
);

-- Index for performance and security queries
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_user_active ON user_sessions(user_id, expires_at) 
WHERE revoked_at IS NULL;
```

### 2. Role-Based Access Control (RBAC)

#### **Principle of Least Privilege**
```sql
-- Create specific roles for different access levels
CREATE ROLE gym_member;
CREATE ROLE gym_trainer;
CREATE ROLE gym_manager;
CREATE ROLE gym_owner;
CREATE ROLE gym_readonly; -- For reporting/analytics

-- Grant minimal necessary permissions
GRANT SELECT ON members TO gym_trainer;
GRANT SELECT, UPDATE ON member_visits TO gym_trainer;
GRANT INSERT ON member_visits TO gym_trainer;

-- Never grant unnecessary permissions
-- DON'T: GRANT ALL ON ALL TABLES TO gym_trainer;
-- DO: Grant specific permissions only
```

#### **Dynamic Permission Checking**
```sql
-- Function to verify user permissions before sensitive operations
CREATE OR REPLACE FUNCTION verify_user_permission(
  p_user_id UUID,
  p_permission VARCHAR(100),
  p_resource_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  has_permission BOOLEAN := FALSE;
  user_org_id UUID;
  user_roles TEXT[];
BEGIN
  -- Get user's organization and roles
  SELECT organization_id, ARRAY_AGG(r.name)
  INTO user_org_id, user_roles
  FROM organization_memberships om
  JOIN roles r ON om.role_id = r.id
  WHERE om.user_id = p_user_id 
    AND om.status = 'active'
  GROUP BY organization_id;
  
  -- Check if user has required permission
  SELECT EXISTS (
    SELECT 1 FROM role_permissions rp
    JOIN roles r ON rp.role_id = r.id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE r.name = ANY(user_roles)
      AND p.name = p_permission
      AND rp.granted = true
  ) INTO has_permission;
  
  -- Log permission check for audit
  INSERT INTO security_audit_log (
    user_id, action, resource, permission_checked, granted, ip_address
  ) VALUES (
    p_user_id, 'permission_check', p_resource_id::TEXT, p_permission, has_permission, inet_client_addr()
  );
  
  RETURN has_permission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🛡️ Row Level Security (RLS)

### 1. Comprehensive RLS Implementation

#### **Multi-Tenant Data Isolation**
```sql
-- Enable RLS on all sensitive tables
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;

-- Organization-level isolation
CREATE POLICY "organization_isolation" ON members
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id 
      FROM organization_memberships 
      WHERE user_id = auth.uid() 
        AND status = 'active'
    )
  );

-- Location-level restrictions
CREATE POLICY "location_access_control" ON members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM organization_memberships om
      WHERE om.user_id = auth.uid()
        AND om.organization_id = members.organization_id
        AND om.status = 'active'
        AND (
          om.location_access = '{}' OR -- All locations
          members.primary_location_id::text = ANY(om.location_access)
        )
    )
  );
```

#### **Time-Based Access Control**
```sql
-- Business hours policy
CREATE POLICY "business_hours_access" ON sensitive_operations
  FOR ALL USING (
    -- Allow 24/7 for owners/admins
    EXISTS (
      SELECT 1 FROM organization_memberships om
      JOIN roles r ON om.role_id = r.id
      WHERE om.user_id = auth.uid()
        AND r.name IN ('owner', 'admin')
    ) OR
    -- Restrict others to business hours
    (
      EXTRACT(hour FROM now()) BETWEEN 6 AND 22 AND
      EXTRACT(dow FROM now()) BETWEEN 1 AND 6
    )
  );

-- Temporary access with expiration
CREATE POLICY "temporary_access" ON member_data
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM temporary_access_grants tag
      WHERE tag.user_id = auth.uid()
        AND tag.resource_type = 'member_data'
        AND tag.resource_id = member_data.id
        AND tag.expires_at > now()
        AND tag.is_active = true
    )
  );
```

### 2. Advanced RLS Patterns

#### **Hierarchical Access Control**
```sql
-- Managers can see their team's data
CREATE POLICY "hierarchical_team_access" ON staff_activities
  FOR SELECT USING (
    -- Own data
    staff_id = auth.uid() OR
    -- Direct reports
    EXISTS (
      SELECT 1 FROM organization_memberships om1
      JOIN organization_memberships om2 ON om1.organization_id = om2.organization_id
      JOIN roles r1 ON om1.role_id = r1.id
      JOIN roles r2 ON om2.role_id = r2.id
      WHERE om1.user_id = auth.uid()
        AND om2.user_id = staff_activities.staff_id
        AND r1.level > r2.level -- Manager has higher level than staff
    )
  );
```

#### **Data Classification Policies**
```sql
-- Sensitive data requires higher privileges
CREATE POLICY "sensitive_data_access" ON member_health_records
  FOR SELECT USING (
    -- Medical staff only
    EXISTS (
      SELECT 1 FROM staff_certifications sc
      WHERE sc.user_id = auth.uid()
        AND sc.certification_type = 'medical'
        AND sc.is_valid = true
    ) OR
    -- Owner with business justification
    (
      EXISTS (SELECT 1 FROM organizations WHERE owner_id = auth.uid()) AND
      current_setting('app.business_justification', true) IS NOT NULL
    )
  );
```

---

## 🔒 Data Protection & Encryption

### 1. Encryption at Rest

#### **Column-Level Encryption**
```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive data
CREATE TABLE encrypted_member_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id),
  
  -- Encrypted fields
  encrypted_ssn BYTEA, -- Social security number
  encrypted_payment_info BYTEA, -- Credit card data
  encrypted_medical_notes BYTEA, -- Health information
  
  -- Encryption metadata
  encryption_key_id VARCHAR(100) NOT NULL,
  encrypted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Function to encrypt sensitive data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(
  data TEXT,
  data_type VARCHAR(50)
)
RETURNS BYTEA AS $$
DECLARE
  encryption_key TEXT;
BEGIN
  -- Get encryption key based on data type and user permissions
  encryption_key := current_setting('app.encryption_key_' || data_type);
  
  -- Encrypt the data
  RETURN pgp_sym_encrypt(data, encryption_key);
EXCEPTION WHEN OTHERS THEN
  -- Log encryption attempt
  INSERT INTO security_audit_log (action, details, error_message)
  VALUES ('encryption_attempt', data_type, SQLERRM);
  
  RAISE EXCEPTION 'Encryption failed for data type: %', data_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrypt (with audit trail)
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(
  encrypted_data BYTEA,
  data_type VARCHAR(50),
  business_justification TEXT
)
RETURNS TEXT AS $$
DECLARE
  encryption_key TEXT;
  decrypted_data TEXT;
BEGIN
  -- Verify user has permission to decrypt this data type
  IF NOT verify_user_permission(auth.uid(), 'decrypt_' || data_type) THEN
    RAISE EXCEPTION 'Insufficient permissions to decrypt %', data_type;
  END IF;
  
  -- Require business justification for sensitive data
  IF business_justification IS NULL OR length(trim(business_justification)) < 10 THEN
    RAISE EXCEPTION 'Business justification required for decryption';
  END IF;
  
  -- Get encryption key
  encryption_key := current_setting('app.encryption_key_' || data_type);
  
  -- Decrypt data
  decrypted_data := pgp_sym_decrypt(encrypted_data, encryption_key);
  
  -- Log decryption for audit
  INSERT INTO security_audit_log (
    user_id, action, resource, business_justification, ip_address
  ) VALUES (
    auth.uid(), 'data_decryption', data_type, business_justification, inet_client_addr()
  );
  
  RETURN decrypted_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. Data Masking & Anonymization

#### **Dynamic Data Masking**
```sql
-- Function to mask sensitive data based on user role
CREATE OR REPLACE FUNCTION mask_sensitive_data(
  data TEXT,
  data_type VARCHAR(50),
  user_role VARCHAR(50)
)
RETURNS TEXT AS $$
BEGIN
  CASE data_type
    WHEN 'email' THEN
      CASE user_role
        WHEN 'owner', 'manager' THEN RETURN data; -- Full access
        WHEN 'trainer' THEN RETURN left(data, 3) || '***@' || split_part(data, '@', 2); -- Partial
        ELSE RETURN '***@***.com'; -- Masked
      END CASE;
    
    WHEN 'phone' THEN
      CASE user_role
        WHEN 'owner', 'manager' THEN RETURN data;
        WHEN 'trainer' THEN RETURN left(data, 3) || '***' || right(data, 4);
        ELSE RETURN '***-***-****';
      END CASE;
      
    WHEN 'payment_card' THEN
      CASE user_role
        WHEN 'owner' THEN RETURN data;
        ELSE RETURN '****-****-****-' || right(data, 4);
      END CASE;
      
    ELSE
      RETURN data;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- View with automatic data masking
CREATE VIEW members_masked AS
SELECT 
  id,
  first_name,
  last_name,
  mask_sensitive_data(email, 'email', get_user_role()) as email,
  mask_sensitive_data(phone, 'phone', get_user_role()) as phone,
  -- Don't expose sensitive fields to unauthorized users
  CASE WHEN get_user_role() IN ('owner', 'manager') THEN date_of_birth ELSE NULL END as date_of_birth,
  membership_type,
  status,
  created_at
FROM members;
```

---

## 🔍 Audit & Monitoring

### 1. Comprehensive Audit Logging

#### **Security Audit Table**
```sql
CREATE TABLE security_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Who
  user_id UUID REFERENCES auth.users(id),
  session_id UUID,
  impersonated_by UUID REFERENCES auth.users(id), -- If user is being impersonated
  
  -- What
  action VARCHAR(100) NOT NULL, -- 'login', 'data_access', 'permission_change', etc.
  resource_type VARCHAR(100), -- 'member', 'payment', 'staff', etc.
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  
  -- Where
  ip_address INET,
  user_agent TEXT,
  location_country VARCHAR(2),
  location_city VARCHAR(100),
  
  -- Why
  business_justification TEXT,
  
  -- Security context
  risk_score INTEGER DEFAULT 0, -- 0-100
  security_flags TEXT[], -- ['suspicious_location', 'unusual_time', 'bulk_operation']
  
  -- Compliance
  compliance_category VARCHAR(50), -- 'GDPR', 'PCI_DSS', 'HIPAA'
  retention_period INTERVAL DEFAULT INTERVAL '7 years',
  
  -- Metadata
  request_id UUID, -- Trace requests across services
  api_endpoint VARCHAR(255),
  response_status INTEGER,
  processing_time_ms INTEGER,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Indexes for efficient querying
CREATE INDEX idx_security_audit_user_action ON security_audit_log(user_id, action);
CREATE INDEX idx_security_audit_resource ON security_audit_log(resource_type, resource_id);
CREATE INDEX idx_security_audit_created_at ON security_audit_log(created_at);
CREATE INDEX idx_security_audit_risk_score ON security_audit_log(risk_score) WHERE risk_score > 50;
CREATE INDEX idx_security_audit_flags ON security_audit_log USING GIN(security_flags);
```

#### **Automated Security Monitoring**
```sql
-- Function to detect suspicious activity
CREATE OR REPLACE FUNCTION detect_suspicious_activity()
RETURNS TRIGGER AS $$
DECLARE
  risk_score INTEGER := 0;
  flags TEXT[] := '{}';
  user_location_history RECORD;
  recent_failed_logins INTEGER;
BEGIN
  -- Check for unusual login location
  SELECT country, city INTO user_location_history
  FROM security_audit_log
  WHERE user_id = NEW.user_id 
    AND action = 'login'
    AND created_at > now() - INTERVAL '30 days'
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF user_location_history.country != NEW.location_country THEN
    risk_score := risk_score + 30;
    flags := array_append(flags, 'unusual_location');
  END IF;
  
  -- Check for unusual time
  IF EXTRACT(hour FROM NEW.created_at) < 6 OR EXTRACT(hour FROM NEW.created_at) > 22 THEN
    risk_score := risk_score + 20;
    flags := array_append(flags, 'unusual_time');
  END IF;
  
  -- Check for recent failed login attempts
  SELECT COUNT(*) INTO recent_failed_logins
  FROM security_audit_log
  WHERE user_id = NEW.user_id
    AND action = 'failed_login'
    AND created_at > now() - INTERVAL '1 hour';
    
  IF recent_failed_logins >= 3 THEN
    risk_score := risk_score + 40;
    flags := array_append(flags, 'multiple_failed_logins');
  END IF;
  
  -- Update risk score and flags
  NEW.risk_score := risk_score;
  NEW.security_flags := flags;
  
  -- Alert on high-risk activities
  IF risk_score >= 70 THEN
    INSERT INTO security_alerts (
      user_id, alert_type, risk_score, details, created_at
    ) VALUES (
      NEW.user_id, 'high_risk_activity', risk_score, 
      'Flags: ' || array_to_string(flags, ', '), now()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to audit log
CREATE TRIGGER security_monitoring_trigger
  BEFORE INSERT ON security_audit_log
  FOR EACH ROW EXECUTE FUNCTION detect_suspicious_activity();
```

### 2. Real-time Security Monitoring

#### **Security Alerts System**
```sql
CREATE TABLE security_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  alert_type VARCHAR(100) NOT NULL, -- 'failed_login', 'unusual_access', 'data_breach'
  severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  risk_score INTEGER DEFAULT 0,
  
  -- Alert details
  title VARCHAR(255) NOT NULL,
  description TEXT,
  details JSONB DEFAULT '{}',
  
  -- Response tracking
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'false_positive')),
  assigned_to UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolution_notes TEXT,
  
  -- Automated response
  auto_response_triggered BOOLEAN DEFAULT false,
  auto_response_actions TEXT[], -- ['lock_account', 'require_mfa', 'notify_admin']
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Function to trigger automated security responses
CREATE OR REPLACE FUNCTION handle_security_alert()
RETURNS TRIGGER AS $$
BEGIN
  -- Critical alerts trigger immediate responses
  IF NEW.severity = 'critical' THEN
    -- Lock user account temporarily
    UPDATE auth.users 
    SET is_locked = true, locked_reason = 'Security alert: ' || NEW.title
    WHERE id = NEW.user_id;
    
    -- Revoke all active sessions
    UPDATE user_sessions 
    SET revoked_at = now(), revoked_reason = 'Security alert'
    WHERE user_id = NEW.user_id AND revoked_at IS NULL;
    
    -- Require MFA on next login
    INSERT INTO user_security_requirements (user_id, requirement_type, expires_at)
    VALUES (NEW.user_id, 'require_mfa', now() + INTERVAL '24 hours');
    
    -- Update alert with automated actions
    NEW.auto_response_triggered := true;
    NEW.auto_response_actions := ARRAY['lock_account', 'revoke_sessions', 'require_mfa'];
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER security_alert_response_trigger
  BEFORE INSERT ON security_alerts
  FOR EACH ROW EXECUTE FUNCTION handle_security_alert();
```

---

## 🚨 Incident Response

### 1. Data Breach Response

#### **Breach Detection & Response**
```sql
-- Table to track potential data breaches
CREATE TABLE security_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type VARCHAR(100) NOT NULL, -- 'data_breach', 'unauthorized_access', 'system_compromise'
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  
  -- Incident details
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  affected_users INTEGER DEFAULT 0,
  affected_data_types TEXT[], -- ['personal_info', 'payment_data', 'health_records']
  estimated_records_affected INTEGER,
  
  -- Timeline
  discovered_at TIMESTAMP WITH TIME ZONE NOT NULL,
  occurred_at TIMESTAMP WITH TIME ZONE, -- When incident actually happened
  contained_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  
  -- Response tracking
  incident_commander UUID REFERENCES auth.users(id),
  status VARCHAR(20) DEFAULT 'investigating' CHECK (status IN ('investigating', 'contained', 'resolved', 'closed')),
  
  -- Legal/compliance
  requires_notification BOOLEAN DEFAULT false,
  notification_authorities TEXT[], -- ['GDPR', 'local_police', 'customers']
  customers_notified_at TIMESTAMP WITH TIME ZONE,
  
  -- Lessons learned
  root_cause TEXT,
  remediation_actions TEXT[],
  prevention_measures TEXT[],
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Function to automatically detect potential breaches
CREATE OR REPLACE FUNCTION detect_potential_breach()
RETURNS void AS $$
DECLARE
  suspicious_activity RECORD;
  bulk_access_threshold INTEGER := 100; -- Alert if more than 100 records accessed
BEGIN
  -- Check for bulk data access
  FOR suspicious_activity IN
    SELECT 
      user_id,
      COUNT(*) as access_count,
      array_agg(DISTINCT resource_type) as data_types
    FROM security_audit_log
    WHERE action = 'data_access'
      AND created_at > now() - INTERVAL '1 hour'
    GROUP BY user_id
    HAVING COUNT(*) > bulk_access_threshold
  LOOP
    -- Create security incident
    INSERT INTO security_incidents (
      incident_type, severity, title, description, 
      affected_data_types, discovered_at
    ) VALUES (
      'potential_data_breach',
      'high',
      'Bulk data access detected',
      'User ' || suspicious_activity.user_id || ' accessed ' || suspicious_activity.access_count || ' records in 1 hour',
      suspicious_activity.data_types,
      now()
    );
    
    -- Create immediate alert
    INSERT INTO security_alerts (
      user_id, alert_type, severity, title, description
    ) VALUES (
      suspicious_activity.user_id,
      'bulk_data_access',
      'high',
      'Suspicious bulk data access',
      'Accessed ' || suspicious_activity.access_count || ' records in 1 hour'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule to run every 15 minutes
-- SELECT cron.schedule('detect-breaches', '*/15 * * * *', 'SELECT detect_potential_breach();');
```

### 2. Emergency Procedures

#### **Emergency Access Controls**
```sql
-- Emergency lockdown function
CREATE OR REPLACE FUNCTION emergency_lockdown(
  lockdown_reason TEXT,
  authorized_by UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Verify authorization (only owners can trigger lockdown)
  IF NOT EXISTS (
    SELECT 1 FROM organizations 
    WHERE owner_id = authorized_by
  ) THEN
    RAISE EXCEPTION 'Unauthorized lockdown attempt by user %', authorized_by;
  END IF;
  
  -- Revoke all active sessions except for owners
  UPDATE user_sessions 
  SET revoked_at = now(), 
      revoked_reason = 'Emergency lockdown: ' || lockdown_reason
  WHERE revoked_at IS NULL
    AND user_id NOT IN (SELECT owner_id FROM organizations);
  
  -- Create lockdown record
  INSERT INTO security_incidents (
    incident_type, severity, title, description, incident_commander
  ) VALUES (
    'emergency_lockdown', 'critical', 'Emergency System Lockdown',
    lockdown_reason, authorized_by
  );
  
  -- Log the action
  INSERT INTO security_audit_log (
    user_id, action, business_justification
  ) VALUES (
    authorized_by, 'emergency_lockdown', lockdown_reason
  );
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to restore normal operations
CREATE OR REPLACE FUNCTION restore_normal_operations(
  restoration_reason TEXT,
  authorized_by UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Verify authorization
  IF NOT EXISTS (
    SELECT 1 FROM organizations 
    WHERE owner_id = authorized_by
  ) THEN
    RAISE EXCEPTION 'Unauthorized restoration attempt by user %', authorized_by;
  END IF;
  
  -- Update lockdown incident as resolved
  UPDATE security_incidents 
  SET status = 'resolved',
      resolved_at = now(),
      resolution_notes = restoration_reason
  WHERE incident_type = 'emergency_lockdown'
    AND status != 'resolved';
  
  -- Log restoration
  INSERT INTO security_audit_log (
    user_id, action, business_justification
  ) VALUES (
    authorized_by, 'restore_operations', restoration_reason
  );
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🛠️ Security Configuration

### 1. Database Server Security

#### **PostgreSQL Security Settings**
```sql
-- Connection security
ALTER SYSTEM SET ssl = on;
ALTER SYSTEM SET ssl_cert_file = '/path/to/server.crt';
ALTER SYSTEM SET ssl_key_file = '/path/to/server.key';

-- Logging for security monitoring
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_failed_login_attempts = on;
ALTER SYSTEM SET log_statement = 'ddl'; -- Log all DDL statements

-- Connection limits
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET superuser_reserved_connections = 3;

-- Timeout settings
ALTER SYSTEM SET statement_timeout = '300s'; -- 5 minutes max query time
ALTER SYSTEM SET idle_in_transaction_session_timeout = '60s';

-- Reload configuration
SELECT pg_reload_conf();
```

### 2. Application-Level Security

#### **Security Headers & Settings**
```sql
-- Function to validate and sanitize input
CREATE OR REPLACE FUNCTION sanitize_input(
  input_text TEXT,
  input_type VARCHAR(50)
)
RETURNS TEXT AS $$
BEGIN
  -- Remove potentially dangerous characters
  input_text := regexp_replace(input_text, '[<>\"''();]', '', 'g');
  
  CASE input_type
    WHEN 'email' THEN
      -- Validate email format
      IF input_text !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email format';
      END IF;
      
    WHEN 'phone' THEN
      -- Remove all non-digits and validate length
      input_text := regexp_replace(input_text, '[^0-9+]', '', 'g');
      IF length(input_text) < 10 OR length(input_text) > 15 THEN
        RAISE EXCEPTION 'Invalid phone number format';
      END IF;
      
    WHEN 'name' THEN
      -- Only allow letters, spaces, hyphens, apostrophes
      input_text := regexp_replace(input_text, '[^A-Za-z\s\-'']', '', 'g');
      
  END CASE;
  
  RETURN trim(input_text);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Rate limiting function
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action VARCHAR(100),
  p_max_attempts INTEGER DEFAULT 10,
  p_time_window INTERVAL DEFAULT INTERVAL '1 hour'
)
RETURNS BOOLEAN AS $$
DECLARE
  attempt_count INTEGER;
BEGIN
  -- Count recent attempts
  SELECT COUNT(*) INTO attempt_count
  FROM security_audit_log
  WHERE user_id = p_user_id
    AND action = p_action
    AND created_at > now() - p_time_window;
  
  -- Check if limit exceeded
  IF attempt_count >= p_max_attempts THEN
    -- Log rate limit violation
    INSERT INTO security_audit_log (
      user_id, action, security_flags
    ) VALUES (
      p_user_id, 'rate_limit_exceeded', ARRAY['rate_limiting']
    );
    
    RETURN false;
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📋 Security Checklist

### **Daily Security Tasks**
- [ ] Review security audit logs for anomalies
- [ ] Check failed login attempts and unusual access patterns
- [ ] Monitor active sessions for suspicious activity
- [ ] Verify backup integrity and encryption
- [ ] Review and respond to security alerts

### **Weekly Security Tasks**
- [ ] Analyze security metrics and trends
- [ ] Review user permissions and role assignments
- [ ] Check for inactive accounts that should be disabled
- [ ] Validate encryption key rotation schedule
- [ ] Review incident response procedures

### **Monthly Security Tasks**
- [ ] Conduct security vulnerability assessment
- [ ] Review and update security policies
- [ ] Test disaster recovery procedures
- [ ] Audit database access patterns
- [ ] Update security training materials

### **Quarterly Security Tasks**
- [ ] Comprehensive security audit
- [ ] Penetration testing (internal or external)
- [ ] Review compliance requirements (GDPR, PCI-DSS)
- [ ] Update incident response runbooks
- [ ] Security awareness training for all staff

---

## 🚨 Security Red Flags

### **Immediate Investigation Required**
- Multiple failed login attempts from single IP
- Unusual data access patterns (bulk downloads)
- Login attempts from new geographic locations
- After-hours access to sensitive data
- Privilege escalation attempts
- Multiple users accessing same account

### **Emergency Response Triggers**
- Suspected data breach or unauthorized access
- Detection of malware or system compromise
- Critical security vulnerability discovered
- Regulatory compliance violation
- Insider threat indicators
- External security incident affecting similar organizations

---

*Remember: Security is not a one-time setup but an ongoing process requiring constant vigilance, regular updates, and continuous improvement.*
