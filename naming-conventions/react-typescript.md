# React & TypeScript Naming Conventions

## 🎯 React-Specific Patterns

### Component Props Pattern
```typescript
// ✅ Comprehensive props interface
interface LeadInteractionDashboardProps {
  // Required props first
  leadId: string
  lead: Lead
  
  // Optional props
  initialTab?: string
  className?: string
  
  // Boolean props with clear prefixes
  isLoading?: boolean
  isEditable?: boolean
  hasUnsavedChanges?: boolean
  canDelete?: boolean
  shouldAutoSave?: boolean
  
  // Event handlers with "on" prefix
  onLeadUpdate?: (lead: Lead) => void
  onCallStart?: (leadId: string) => void
  onStatusChange?: (leadId: string, statusId: number) => void
  onClose?: () => void
  onSave?: (data: LeadFormData) => void
  
  // Render props / children
  renderHeader?: (lead: Lead) => React.ReactNode
  children?: React.ReactNode
}
```

### React Hook Patterns
```typescript
// ✅ Data fetching hook
export const useLeadManagement = () => {
  // Queries first
  const leadsQuery = useQuery({
    queryKey: ['leads'],
    queryFn: getLeads
  })
  
  // Mutations
  const createMutation = useMutation({
    mutationFn: createLead,
    onSuccess: () => queryClient.invalidateQueries(['leads'])
  })
  
  // Return organized object
  return {
    // Data (most important first)
    leads: leadsQuery.data || [],
    selectedLead: selectedLeadQuery.data,
    
    // Loading states
    isLoading: leadsQuery.isLoading,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    
    // Actions (verbs)
    createLead: createMutation.mutate,
    updateLead: updateMutation.mutate,
    deleteLead: deleteMutation.mutate,
    selectLead: setSelectedLeadId,
    
    // Error states
    error: leadsQuery.error,
    createError: createMutation.error,
    
    // Utilities (last)
    refetch: leadsQuery.refetch,
    reset: () => { /* reset logic */ }
  }
}

// ✅ Form management hook
export const useLeadForm = (initialData?: Lead) => {
  const [formData, setFormData] = useState<LeadFormData>({
    firstName: initialData?.first_name || '',
    lastName: initialData?.last_name || '',
    email: initialData?.email || '',
    phone: initialData?.phone || '',
  })
  
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isDirty, setIsDirty] = useState(false)
  
  // Clear action naming
  const updateField = useCallback((field: keyof LeadFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    setIsDirty(true)
    // Clear error for this field
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }))
    }
  }, [errors])
  
  const validateForm = useCallback(() => {
    const newErrors: Record<string, string> = {}
    
    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required'
    }
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required'
    }
    
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }, [formData])
  
  const resetForm = useCallback(() => {
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
    })
    setErrors({})
    setIsDirty(false)
  }, [])
  
  return {
    // Form state
    formData,
    errors,
    isDirty,
    
    // Actions
    updateField,
    validateForm,
    resetForm,
    
    // Computed values
    isValid: Object.keys(errors).length === 0,
    hasChanges: isDirty
  }
}
```

### Event Handler Naming
```typescript
// ✅ Component event handlers
const LeadCard = ({ lead, onLeadSelect, onCallStart }: LeadCardProps) => {
  // Internal handlers use "handle" prefix
  const handleCardClick = () => {
    onLeadSelect(lead.id)
  }
  
  const handleCallButtonClick = (e: React.MouseEvent) => {
    e.stopPropagation() // Prevent card selection
    onCallStart(lead.id)
  }
  
  const handleStatusChange = (statusId: number) => {
    // Could trigger multiple external handlers
    onStatusChange?.(lead.id, statusId)
    onLeadUpdate?.({ ...lead, current_status_id: statusId })
  }
  
  return (
    <div onClick={handleCardClick}>
      <button onClick={handleCallButtonClick}>Call</button>
      <select onChange={(e) => handleStatusChange(Number(e.target.value))}>
        {/* options */}
      </select>
    </div>
  )
}
```

## 🔤 TypeScript-Specific Patterns

### Type Definition Naming
```typescript
// ✅ Clear type naming
export type LeadId = string
export type StatusId = number
export type CallSessionId = string

// Union types
export type LeadStatus = 'new' | 'contacted' | 'qualified' | 'lost' | 'won'
export type CallOutcome = 'no_answer' | 'no_time' | 'has_time'
export type ConsultationType = 'strategy' | 'technical' | 'product' | 'discovery'

// Utility types
export type CreateLeadData = Omit<Lead, 'id' | 'created_at' | 'updated_at'>
export type UpdateLeadData = Partial<Pick<Lead, 'first_name' | 'last_name' | 'email' | 'phone'>>
export type LeadWithStatus = Lead & { status: LeadStatus }

// Function types
export type LeadUpdateHandler = (leadId: string, data: UpdateLeadData) => void
export type CallStartHandler = (leadId: string) => Promise<void>
export type FormSubmitHandler<T> = (data: T) => Promise<void>
```

### Generic Type Naming
```typescript
// ✅ Single letter generics (standard practice)
interface ApiResponse<T> {
  data: T
  success: boolean
  message?: string
}

interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
}

interface Repository<T, K = string> {
  findById: (id: K) => Promise<T | null>
  create: (data: Omit<T, 'id'>) => Promise<T>
  update: (id: K, data: Partial<T>) => Promise<T>
  delete: (id: K) => Promise<void>
}

// ✅ Descriptive generics when needed
interface FormField<TValue = string> {
  name: string
  value: TValue
  onChange: (value: TValue) => void
  validation?: (value: TValue) => string | undefined
}
```

### React Component Type Patterns
```typescript
// ✅ Component with generic props
interface DataTableProps<T> {
  data: T[]
  columns: Array<{
    key: keyof T
    label: string
    render?: (value: T[keyof T], item: T) => React.ReactNode
  }>
  onRowSelect?: (item: T) => void
  onRowAction?: (action: string, item: T) => void
}

export const DataTable = <T extends Record<string, unknown>>({
  data,
  columns,
  onRowSelect,
  onRowAction
}: DataTableProps<T>) => {
  // Component implementation
}

// ✅ Forward ref component
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  isLoading?: boolean
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', isLoading, children, ...props }, ref) => {
    return (
      <button ref={ref} {...props}>
        {isLoading ? 'Loading...' : children}
      </button>
    )
  }
)

Button.displayName = 'Button'
```

### Enum vs Const Assertions
```typescript
// ✅ Use const assertions for simple string unions
export const LEAD_STATUS = {
  NEW: 'new',
  CONTACTED: 'contacted',
  QUALIFIED: 'qualified',
  WON: 'won',
  LOST: 'lost'
} as const

export type LeadStatus = typeof LEAD_STATUS[keyof typeof LEAD_STATUS]

// ✅ Use enums for complex cases or when you need reverse mapping
export enum HttpStatusCode {
  OK = 200,
  CREATED = 201,
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  NOT_FOUND = 404,
  INTERNAL_SERVER_ERROR = 500
}
```

## 🎣 Hook Composition Patterns

### Compound Hook Pattern
```typescript
// ✅ Main hook that composes other hooks
export const useLeadInteractionDashboard = (leadId: string) => {
  // Compose multiple focused hooks
  const leadData = useLeadDetails(leadId)
  const callSession = useCallSession()
  const consultation = useConsultationBooking()
  const activities = useActivityTracking(leadId)
  
  // Combined loading state
  const isLoading = leadData.isLoading || activities.isLoading
  
  // Combined actions
  const handleCallStart = useCallback(async () => {
    if (!leadData.lead) return
    
    try {
      await callSession.startCall(leadId, 'initial')
      activities.logActivity({
        type: 'call_started',
        leadId
      })
    } catch (error) {
      // Handle error
    }
  }, [leadData.lead, callSession, activities, leadId])
  
  const handleConsultationSchedule = useCallback(async (data: ConsultationData) => {
    try {
      await consultation.scheduleConsultation({
        leadId,
        ...data
      })
      activities.logActivity({
        type: 'consultation_scheduled',
        leadId
      })
    } catch (error) {
      // Handle error
    }
  }, [consultation, activities, leadId])
  
  return {
    // Data from composed hooks
    lead: leadData.lead,
    activities: activities.activities,
    currentCall: callSession.currentSession,
    
    // Combined states
    isLoading,
    hasActiveCall: callSession.isActive,
    
    // Combined actions
    handleCallStart,
    handleConsultationSchedule,
    
    // Pass through specific actions
    endCall: callSession.endCall,
    updateLead: leadData.updateLead,
    addNote: activities.addNote
  }
}

// ✅ Focused hooks for specific functionality
export const useLeadDetails = (leadId: string) => {
  const leadQuery = useQuery({
    queryKey: ['leads', leadId],
    queryFn: () => getLead(leadId),
    enabled: !!leadId
  })
  
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateLeadData }) => 
      updateLead(id, data)
  })
  
  return {
    lead: leadQuery.data,
    isLoading: leadQuery.isLoading,
    error: leadQuery.error,
    updateLead: updateMutation.mutate,
    isUpdating: updateMutation.isPending
  }
}
```

### Custom Hook with Cleanup
```typescript
// ✅ Hook with proper cleanup and error handling
export const useCallTimer = () => {
  const [startTime, setStartTime] = useState<Date | null>(null)
  const [duration, setDuration] = useState(0)
  const [isRunning, setIsRunning] = useState(false)
  
  // Timer effect with cleanup
  useEffect(() => {
    let intervalId: NodeJS.Timeout
    
    if (isRunning && startTime) {
      intervalId = setInterval(() => {
        setDuration(Date.now() - startTime.getTime())
      }, 1000)
    }
    
    return () => {
      if (intervalId) {
        clearInterval(intervalId)
      }
    }
  }, [isRunning, startTime])
  
  const startTimer = useCallback(() => {
    setStartTime(new Date())
    setIsRunning(true)
    setDuration(0)
  }, [])
  
  const stopTimer = useCallback(() => {
    setIsRunning(false)
  }, [])
  
  const resetTimer = useCallback(() => {
    setStartTime(null)
    setIsRunning(false)
    setDuration(0)
  }, [])
  
  // Format duration for display
  const formattedDuration = useMemo(() => {
    const minutes = Math.floor(duration / 60000)
    const seconds = Math.floor((duration % 60000) / 1000)
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }, [duration])
  
  return {
    duration,
    formattedDuration,
    isRunning,
    startTimer,
    stopTimer,
    resetTimer
  }
}
```

## 🔧 Advanced TypeScript Patterns

### Discriminated Unions
```typescript
// ✅ Activity types with discriminated unions
interface BaseActivity {
  id: string
  leadId: string
  createdAt: string
  createdBy: string
}

interface CallActivity extends BaseActivity {
  type: 'call'
  duration: number
  outcome: 'no_answer' | 'no_time' | 'has_time'
  notes?: string
}

interface EmailActivity extends BaseActivity {
  type: 'email'
  subject: string
  templateId?: string
  sentAt: string
}

interface ConsultationActivity extends BaseActivity {
  type: 'consultation'
  scheduledDate: string
  consultationType: 'strategy' | 'technical' | 'product'
  status: 'scheduled' | 'completed' | 'cancelled'
}

export type LeadActivity = CallActivity | EmailActivity | ConsultationActivity

// ✅ Type-safe activity handlers
const handleActivityAction = (activity: LeadActivity) => {
  switch (activity.type) {
    case 'call':
      // TypeScript knows this is CallActivity
      console.log(`Call duration: ${activity.duration}`)
      break
    case 'email':
      // TypeScript knows this is EmailActivity
      console.log(`Email subject: ${activity.subject}`)
      break
    case 'consultation':
      // TypeScript knows this is ConsultationActivity
      console.log(`Consultation type: ${activity.consultationType}`)
      break
    default:
      // TypeScript ensures exhaustive checking
      const _exhaustive: never = activity
      break
  }
}
```

### Branded Types for IDs
```typescript
// ✅ Branded types prevent ID mixups
declare const __brand: unique symbol
type Brand<T, TBrand> = T & { [__brand]: TBrand }

export type LeadId = Brand<string, 'LeadId'>
export type CallSessionId = Brand<string, 'CallSessionId'>
export type ConsultationId = Brand<string, 'ConsultationId'>
export type UserId = Brand<string, 'UserId'>

// Helper functions to create branded IDs
export const createLeadId = (id: string): LeadId => id as LeadId
export const createCallSessionId = (id: string): CallSessionId => id as CallSessionId

// ✅ Now these are type-safe and prevent mixups
const startCall = (leadId: LeadId, sessionId: CallSessionId) => {
  // Implementation
}

// This would be a TypeScript error:
// startCall(sessionId, leadId) // Error: arguments swapped
```

### Template Literal Types
```typescript
// ✅ Template literal types for API endpoints
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'
type ApiVersion = 'v1' | 'v2'
type ApiResource = 'leads' | 'consultations' | 'activities' | 'users'

type ApiEndpoint = `/api/${ApiVersion}/${ApiResource}`
type ApiEndpointWithId = `/api/${ApiVersion}/${ApiResource}/${string}`

// ✅ Event naming with template literals
type LeadEventType = 'created' | 'updated' | 'deleted' | 'status_changed'
type CallEventType = 'started' | 'ended' | 'paused' | 'resumed'

type LeadEvent = `lead:${LeadEventType}`
type CallEvent = `call:${CallEventType}`
type AppEvent = LeadEvent | CallEvent

// Usage in event system
const emitEvent = (event: AppEvent, data: unknown) => {
  // Type-safe event emission
}

emitEvent('lead:created', leadData) // ✅ Valid
emitEvent('call:started', callData) // ✅ Valid
emitEvent('invalid:event', data) // ❌ TypeScript error
```

## 🧩 Component Composition Patterns

### Compound Components
```typescript
// ✅ Compound component pattern
interface LeadCardContextType {
  lead: Lead
  isSelected: boolean
  onSelect: () => void
}

const LeadCardContext = React.createContext<LeadCardContextType | null>(null)

const useLeadCardContext = () => {
  const context = useContext(LeadCardContext)
  if (!context) {
    throw new Error('useLeadCardContext must be used within a LeadCard component')
  }
  return context
}

// Main component
interface LeadCardProps {
  lead: Lead
  isSelected?: boolean
  onSelect?: (leadId: string) => void
  children: React.ReactNode
}

const LeadCardRoot = ({ lead, isSelected = false, onSelect, children }: LeadCardProps) => {
  const handleSelect = useCallback(() => {
    onSelect?.(lead.id)
  }, [lead.id, onSelect])
  
  const contextValue: LeadCardContextType = {
    lead,
    isSelected,
    onSelect: handleSelect
  }
  
  return (
    <LeadCardContext.Provider value={contextValue}>
      <div className={`lead-card ${isSelected ? 'lead-card--selected' : ''}`}>
        {children}
      </div>
    </LeadCardContext.Provider>
  )
}

// Sub-components
const LeadCardHeader = ({ children }: { children: React.ReactNode }) => {
  const { lead } = useLeadCardContext()
  
  return (
    <div className="lead-card__header">
      <h3>{lead.first_name} {lead.last_name}</h3>
      {children}
    </div>
  )
}

const LeadCardActions = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="lead-card__actions">
      {children}
    </div>
  )
}

const LeadCardSelectButton = () => {
  const { isSelected, onSelect } = useLeadCardContext()
  
  return (
    <button 
      onClick={onSelect}
      className={`select-button ${isSelected ? 'select-button--selected' : ''}`}
    >
      {isSelected ? 'Selected' : 'Select'}
    </button>
  )
}

// Export compound component
export const LeadCard = {
  Root: LeadCardRoot,
  Header: LeadCardHeader,
  Actions: LeadCardActions,
  SelectButton: LeadCardSelectButton
}

// Usage
const LeadList = ({ leads, selectedLeadId, onLeadSelect }: LeadListProps) => {
  return (
    <div>
      {leads.map(lead => (
        <LeadCard.Root 
          key={lead.id} 
          lead={lead}
          isSelected={selectedLeadId === lead.id}
          onSelect={onLeadSelect}
        >
          <LeadCard.Header>
            <span className="lead-status">{lead.status}</span>
          </LeadCard.Header>
          <LeadCard.Actions>
            <LeadCard.SelectButton />
            <button>Call</button>
            <button>Email</button>
          </LeadCard.Actions>
        </LeadCard.Root>
      ))}
    </div>
  )
}
```

### Render Props Pattern
```typescript
// ✅ Render props for flexible data sharing
interface DataFetcherProps<T> {
  queryKey: string[]
  queryFn: () => Promise<T>
  children: (props: {
    data: T | undefined
    isLoading: boolean
    error: Error | null
    refetch: () => void
  }) => React.ReactNode
}

export const DataFetcher = <T,>({ queryKey, queryFn, children }: DataFetcherProps<T>) => {
  const query = useQuery({
    queryKey,
    queryFn
  })
  
  return (
    <>
      {children({
        data: query.data,
        isLoading: query.isLoading,
        error: query.error,
        refetch: query.refetch
      })}
    </>
  )
}

// Usage
const LeadDetails = ({ leadId }: { leadId: string }) => {
  return (
    <DataFetcher
      queryKey={['leads', leadId]}
      queryFn={() => getLead(leadId)}
    >
      {({ data: lead, isLoading, error, refetch }) => {
        if (isLoading) return <div>Loading...</div>
        if (error) return <div>Error: {error.message}</div>
        if (!lead) return <div>Lead not found</div>
        
        return (
          <div>
            <h1>{lead.first_name} {lead.last_name}</h1>
            <button onClick={() => refetch()}>Refresh</button>
          </div>
        )
      }}
    </DataFetcher>
  )
}
```

This covers the essential React and TypeScript naming conventions and patterns. The key principles are:

1. **Consistency** - Use the same patterns throughout
2. **Clarity** - Names should be self-documenting
3. **Type Safety** - Leverage TypeScript's type system
4. **Composability** - Design for reusability and composition
5. **AI-Friendly** - Patterns that AI tools can easily follow and extend
