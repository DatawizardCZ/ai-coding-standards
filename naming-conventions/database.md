# Database Naming Conventions

## 🗃️ PostgreSQL/Supabase Database Conventions

### Table Naming
- **Always use snake_case**
- **Use plural for entity tables**
- **Use descriptive names for junction/reference tables**

```sql
✅ Good Examples:
leads
lead_status
lead_activity
lead_call_session
call_script_template
call_script_question
lead_consultation
user_profiles

❌ Bad Examples:
Lead
leadStatus
leadactivity
LeadCallSession
CallScriptTemplate
```

### Column Naming
- **Always use snake_case**
- **Be descriptive and specific**
- **Use consistent patterns for common fields**

```sql
✅ Good Examples:
-- Primary keys
id (uuid, primary key)

-- Timestamps
created_at
updated_at
scheduled_at
completed_at

-- Foreign keys
lead_id
user_id
status_id
template_id

-- Boolean fields
is_active
is_deleted
has_children
can_edit

-- Text fields
first_name
last_name
email_address
phone_number

❌ Bad Examples:
firstName
lastName
emailAddress
phoneNumber
leadId
userId
isActive
```

### Foreign Key Naming
- **Use {referenced_table_singular}_id pattern**
- **Be explicit about relationships**

```sql
✅ Good Examples:
leads table:
  current_status_id → lead_status.id
  assigned_to → user_profiles.id
  next_step_type_id → lead_next_step_type.id

lead_activity table:
  lead_id → leads.id
  activity_type_id → lead_activity_type.id
  created_by → user_profiles.id

call_script_question table:
  template_id → call_script_template.id

❌ Bad Examples:
status → should be current_status_id
user → should be assigned_to or created_by
type → should be activity_type_id
```

## 🏗️ TypeScript Database Integration

### Database Type Definitions
- **Use PascalCase for TypeScript interfaces**
- **Keep field names as snake_case (matching database)**
- **Use Supabase generated types as base**

```typescript
// ✅ Generated Supabase types (base)
export type Database = {
  public: {
    Tables: {
      leads: {
        Row: {
          id: string
          first_name: string
          last_name: string
          email: string
          phone: string | null
          current_status_id: number | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          first_name: string
          last_name: string
          email: string
          phone?: string | null
          current_status_id?: number | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          first_name?: string
          last_name?: string
          email?: string
          phone?: string | null
          current_status_id?: number | null
          updated_at?: string
        }
      }
      // ... other tables
    }
  }
}

// ✅ Derived types for application use
export type Lead = Database['public']['Tables']['leads']['Row']
export type LeadInsert = Database['public']['Tables']['leads']['Insert']
export type LeadUpdate = Database['public']['Tables']['leads']['Update']

export type LeadStatus = Database['public']['Tables']['lead_status']['Row']
export type LeadActivity = Database['public']['Tables']['lead_activity']['Row']
export type CallSession = Database['public']['Tables']['lead_call_session']['Row']
```

### Extended Types with Joins
```typescript
// ✅ Types for joined data
export interface LeadWithStatus extends Lead {
  status: LeadStatus
}

export interface LeadWithActivities extends Lead {
  activities: LeadActivity[]
}

export interface CallSessionWithResponses extends CallSession {
  responses: CallResponse[]
  template: CallScriptTemplate
}

export interface LeadFullDetails extends Lead {
  status: LeadStatus
  activities: LeadActivity[]
  notes: LeadNote[]
  consultations: Consultation[]
  assignedUser?: UserProfile
}
```

### API Function Naming
- **Use camelCase for TypeScript functions**
- **Use clear verbs that describe database operations**
- **Group related operations**

```typescript
// ✅ CRUD operations
export const createLead = async (data: LeadInsert): Promise<Lead> => {
  const { data: lead, error } = await supabase
    .from('leads')
    .insert(data)
    .select()
    .single()
  
  if (error) throw error
  return lead
}

export const updateLead = async (id: string, data: LeadUpdate): Promise<Lead> => {
  const { data: lead, error } = await supabase
    .from('leads')
    .update(data)
    .eq('id', id)
    .select()
    .single()
  
  if (error) throw error
  return lead
}

export const deleteLead = async (id: string): Promise<void> => {
  const { error } = await supabase
    .from('leads')
    .delete()
    .eq('id', id)
  
  if (error) throw error
}

export const getLead = async (id: string): Promise<Lead | null> => {
  const { data: lead, error } = await supabase
    .from('leads')
    .select()
    .eq('id', id)
    .single()
  
  if (error && error.code !== 'PGRST116') throw error
  return lead
}

export const getLeads = async (): Promise<Lead[]> => {
  const { data: leads, error } = await supabase
    .from('leads')
    .select()
    .order('created_at', { ascending: false })
  
  if (error) throw error
  return leads || []
}

// ✅ Complex queries with descriptive names
export const getLeadsWithStatus = async (): Promise<LeadWithStatus[]> => {
  const { data: leads, error } = await supabase
    .from('leads')
    .select(`
      *,
      status:lead_status(*)
    `)
    .order('created_at', { ascending: false })
  
  if (error) throw error
  return leads || []
}

export const getLeadActivities = async (leadId: string): Promise<LeadActivity[]> => {
  const { data: activities, error } = await supabase
    .from('lead_activity')
    .select(`
      *,
      activity_type:lead_activity_type(*),
      created_by_user:user_profiles(*)
    `)
    .eq('lead_id', leadId)
    .order('created_at', { ascending: false })
  
  if (error) throw error
  return activities || []
}

export const getActiveCallSession = async (leadId: string): Promise<CallSession | null> => {
  const { data: session, error } = await supabase
    .from('lead_call_session')
    .select()
    .eq('lead_id', leadId)
    .is('call_end', null)
    .single()
  
  if (error && error.code !== 'PGRST116') throw error
  return session
}

// ✅ Status update functions
export const updateLeadStatus = async (
  leadId: string, 
  statusId: number
): Promise<Lead> => {
  const { data: lead, error } = await supabase
    .from('leads')
    .update({ 
      current_status_id: statusId,
      updated_at: new Date().toISOString()
    })
    .eq('id', leadId)
    .select()
    .single()
  
  if (error) throw error
  return lead
}

export const markLeadAsLost = async (
  leadId: string, 
  lossReasonId: number,
  notes?: string
): Promise<void> => {
  // Update lead status
  await updateLeadStatus(leadId, LEAD_STATUS_IDS.LOST)
  
  // Log activity
  await createLeadActivity({
    lead_id: leadId,
    activity_type_id: ACTIVITY_TYPE_IDS.STATUS_CHANGE,
    details: `Lead marked as lost. Reason: ${lossReasonId}`,
    notes
  })
}
```

## 🔄 Database Migration Naming

### Migration File Naming
```
✅ Good Examples:
001_create_leads_table.sql
002_create_lead_status_table.sql
003_add_lead_status_relationship.sql
004_create_lead_activity_table.sql
005_add_call_session_functionality.sql
006_add_consultation_scheduling.sql

❌ Bad Examples:
migration1.sql
leadTable.sql
add_stuff.sql
```

### Migration Content Structure
```sql
-- ✅ Clear migration structure
-- Migration: 003_add_lead_status_relationship.sql
-- Description: Add foreign key relationship from leads to lead_status

-- Add the foreign key column
ALTER TABLE leads 
ADD COLUMN current_status_id INTEGER;

-- Add the foreign key constraint
ALTER TABLE leads 
ADD CONSTRAINT fk_leads_status 
FOREIGN KEY (current_status_id) 
REFERENCES lead_status(id);

-- Create index for performance
CREATE INDEX idx_leads_current_status 
ON leads(current_status_id);

-- Set default status for existing leads
UPDATE leads 
SET current_status_id = (
  SELECT id FROM lead_status WHERE code = 'new' LIMIT 1
) 
WHERE current_status_id IS NULL;
```

## 📊 Query Patterns and Naming

### Supabase Query Builder Patterns
```typescript
// ✅ Clear query variable naming
export const getLeadDashboardData = async (userId: string) => {
  // Multiple queries with descriptive names
  const leadsQuery = supabase
    .from('leads')
    .select(`
      id,
      first_name,
      last_name,
      current_status_id,
      status:lead_status(name_en)
    `)
    .eq('assigned_to', userId)
  
  const activitiesQuery = supabase
    .from('lead_activity')
    .select(`
      id,
      lead_id,
      activity_type_id,
      created_at,
      type:lead_activity_type(name_en)
    `)
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
  
  const consultationsQuery = supabase
    .from('lead_consultation')
    .select(`
      id,
      lead_id,
      scheduled_date,
      status
    `)
    .eq('status', 'scheduled')
    .gte('scheduled_date', new Date().toISOString())
  
  // Execute queries
  const [leadsResult, activitiesResult, consultationsResult] = await Promise.all([
    leadsQuery,
    activitiesQuery,
    consultationsQuery
  ])
  
  // Check for errors
  if (leadsResult.error) throw leadsResult.error
  if (activitiesResult.error) throw activitiesResult.error
  if (consultationsResult.error) throw consultationsResult.error
  
  return {
    leads: leadsResult.data || [],
    recentActivities: activitiesResult.data || [],
    upcomingConsultations: consultationsResult.data || []
  }
}

// ✅ Search and filter functions
export const searchLeads = async (searchTerm: string): Promise<Lead[]> => {
  const { data: leads, error } = await supabase
    .from('leads')
    .select()
    .or(`first_name.ilike.%${searchTerm}%,last_name.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%`)
    .order('created_at', { ascending: false })
  
  if (error) throw error
  return leads || []
}

export const getLeadsByStatus = async (statusId: number): Promise<Lead[]> => {
  const { data: leads, error } = await supabase
    .from('leads')
    .select()
    .eq('current_status_id', statusId)
    .order('updated_at', { ascending: false })
  
  if (error) throw error
  return leads || []
}

export const getLeadsRequiringFollowUp = async (): Promise<Lead[]> => {
  const { data: leads, error } = await supabase
    .from('leads')
    .select(`
      *,
      status:lead_status(*)
    `)
    .not('next_step_date', 'is', null)
    .lte('next_step_date', new Date().toISOString())
    .order('next_step_date', { ascending: true })
  
  if (error) throw error
  return leads || []
}
```

### Real-time Subscription Naming
```typescript
// ✅ Subscription management
export const subscribeToLeadUpdates = (
  leadId: string,
  onUpdate: (lead: Lead) => void
) => {
  const subscription = supabase
    .channel(`lead-${leadId}`)
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'leads',
        filter: `id=eq.${leadId}`
      },
      (payload) => {
        onUpdate(payload.new as Lead)
      }
    )
    .subscribe()
  
  return subscription
}

export const subscribeToLeadActivities = (
  leadId: string,
  onNewActivity: (activity: LeadActivity) => void
) => {
  const subscription = supabase
    .channel(`lead-activities-${leadId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'lead_activity',
        filter: `lead_id=eq.${leadId}`
      },
      (payload) => {
        onNewActivity(payload.new as LeadActivity)
      }
    )
    .subscribe()
  
  return subscription
}
```

## 🔒 Row Level Security (RLS) Naming

### Policy Naming Conventions
```sql
-- ✅ Clear policy names
-- Pattern: {action}_{table}_{condition}

-- Users can only see their own assigned leads
CREATE POLICY "select_leads_assigned_to_user" ON leads
FOR SELECT TO authenticated
USING (assigned_to = auth.uid());

-- Users can update leads they're assigned to
CREATE POLICY "update_leads_assigned_to_user" ON leads
FOR UPDATE TO authenticated
USING (assigned_to = auth.uid());

-- Admins can see all leads
CREATE POLICY "select_leads_admin_access" ON leads
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM user_profiles 
    WHERE user_profiles.id = auth.uid() 
    AND user_profiles.role = 'admin'
  )
);

-- Users can insert activities for their assigned leads
CREATE POLICY "insert_activities_for_assigned_leads" ON lead_activity
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM leads 
    WHERE leads.id = lead_activity.lead_id 
    AND leads.assigned_to = auth.uid()
  )
);
```

This comprehensive database naming guide ensures consistency between your PostgreSQL database schema and TypeScript application code, making it easier for AI tools to understand and work with your data layer.
