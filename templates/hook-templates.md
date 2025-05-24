# Hook Templates

## 🎣 React Query Data Management Hook

Use this template for hooks that manage data fetching and mutations with React Query.

### File Structure
```
File: use-{feature-name}.ts
Location: /hooks/
Hook: use{FeatureName}
Return: Descriptive object with clear property names
```

### Complete Data Management Hook Template
```typescript
// File: use-lead-management.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { 
  createLead, 
  updateLead, 
  deleteLead, 
  getLeads, 
  getLead 
} from '@/lib/api/leads'
import type { Lead, LeadInsert, LeadUpdate } from '@/types/lead-types'

export const useLeadManagement = () => {
  const queryClient = useQueryClient()

  // Queries - Data fetching
  const leadsQuery = useQuery({
    queryKey: ['leads'],
    queryFn: getLeads,
    staleTime: 5 * 60 * 1000, // 5 minutes
  })

  const getLeadQuery = (leadId: string) => useQuery({
    queryKey: ['leads', leadId],
    queryFn: () => getLead(leadId),
    enabled: !!leadId,
    staleTime: 5 * 60 * 1000,
  })

  // Mutations - Data modifications
  const createMutation = useMutation({
    mutationFn: createLead,
    onSuccess: (newLead) => {
      // Update the leads list cache
      queryClient.setQueryData(['leads'], (oldData: Lead[] | undefined) => {
        return oldData ? [newLead, ...oldData] : [newLead]
      })
      // Invalidate to ensure fresh data
      queryClient.invalidateQueries({ queryKey: ['leads'] })
    },
    onError: (error) => {
      console.error('Failed to create lead:', error)
    }
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: LeadUpdate }) => 
      updateLead(id, data),
    onSuccess: (updatedLead, { id }) => {
      // Update specific lead in cache
      queryClient.setQueryData(['leads', id], updatedLead)
      // Update lead in the list
      queryClient.setQueryData(['leads'], (oldData: Lead[] | undefined) => {
        return oldData?.map(lead => 
          lead.id === id ? updatedLead : lead
        )
      })
    },
    onError: (error) => {
      console.error('Failed to update lead:', error)
    }
  })

  const deleteMutation = useMutation({
    mutationFn: deleteLead,
    onSuccess: (_, deletedId) => {
      // Remove from cache
      queryClient.removeQueries({ queryKey: ['leads', deletedId] })
      // Update leads list
      queryClient.setQueryData(['leads'], (oldData: Lead[] | undefined) => {
        return oldData?.filter(lead => lead.id !== deletedId)
      })
    },
    onError: (error) => {
      console.error('Failed to delete lead:', error)
    }
  })

  // Return organized object with clear naming
  return {
    // Data (most important first)
    leads: leadsQuery.data || [],
    isLoading: leadsQuery.isLoading,
    error: leadsQuery.error,
    
    // Actions (verbs)
    createLead: createMutation.mutate,
    updateLead: updateMutation.mutate,
    deleteLead: deleteMutation.mutate,
    
    // Loading states for mutations
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
    
    // Error states for mutations
    createError: createMutation.error,
    updateError: updateMutation.error,
    deleteError: deleteMutation.error,
    
    // Utilities (last)
    getLead: getLeadQuery,
    refetchLeads: leadsQuery.refetch,
    invalidateLeads: () => queryClient.invalidateQueries({ queryKey: ['leads'] })
  }
}
```

## 🔧 Feature-Specific Hook Template

Use this template for hooks that manage specific feature functionality.

### Complete Feature Hook Template
```typescript
// File: use-call-session.ts
import { useState, useCallback } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { 
  startCallSession, 
  endCallSession, 
  submitCallResponse,
  getActiveCallSession 
} from '@/lib/api/call-sessions'
import type { CallSession, CallResponse } from '@/types/call-types'

interface CallSessionState {
  isActive: boolean
  startTime: Date | null
  duration: number
}

export const useCallSession = () => {
  const queryClient = useQueryClient()
  
  // Local state for call session
  const [sessionState, setSessionState] = useState<CallSessionState>({
    isActive: false,
    startTime: null,
    duration: 0
  })

  // Get active session for a lead
  const getActiveSessionQuery = (leadId: string) => useQuery({
    queryKey: ['call-session', 'active', leadId],
    queryFn: () => getActiveCallSession(leadId),
    enabled: !!leadId,
    refetchInterval: sessionState.isActive ? 5000 : false, // Poll while active
  })

  // Start call session
  const startCallMutation = useMutation({
    mutationFn: ({ leadId, templateId }: { leadId: string; templateId: string }) =>
      startCallSession(leadId, templateId),
    onSuccess: (session) => {
      setSessionState({
        isActive: true,
        startTime: new Date(),
        duration: 0
      })
      // Update cache
      queryClient.setQueryData(['call-session', session.id], session)
      queryClient.setQueryData(['call-session', 'active', session.lead_id], session)
    },
    onError: (error) => {
      console.error('Failed to start call session:', error)
    }
  })

  // End call session
  const endCallMutation = useMutation({
    mutationFn: ({ sessionId, outcome }: { sessionId: string; outcome: string }) =>
      endCallSession(sessionId, outcome),
    onSuccess: (session) => {
      setSessionState({
        isActive: false,
        startTime: null,
        duration: 0
      })
      // Update cache
      queryClient.setQueryData(['call-session', session.id], session)
      queryClient.removeQueries({ queryKey: ['call-session', 'active'] })
      // Invalidate related data
      queryClient.invalidateQueries({ queryKey: ['lead-activities'] })
    },
    onError: (error) => {
      console.error('Failed to end call session:', error)
    }
  })

  // Submit call response
  const submitResponseMutation = useMutation({
    mutationFn: submitCallResponse,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['call-responses'] })
    },
    onError: (error) => {
      console.error('Failed to submit response:', error)
    }
  })

  // Helper functions
  const startCall = useCallback(async (leadId: string, templateId: string) => {
    try {
      await startCallMutation.mutateAsync({ leadId, templateId })
    } catch (error) {
      throw error
    }
  }, [startCallMutation])

  const endCall = useCallback(async (sessionId: string, outcome: string) => {
    try {
      await endCallMutation.mutateAsync({ sessionId, outcome })
    } catch (error) {
      throw error
    }
  }, [endCallMutation])

  const submitResponse = useCallback(async (responseData: Omit<CallResponse, 'id' | 'created_at'>) => {
    try {
      await submitResponseMutation.mutateAsync(responseData)
    } catch (error) {
      throw error
    }
  }, [submitResponseMutation])

  return {
    // Session state
    isActive: sessionState.isActive,
    startTime: sessionState.startTime,
    duration: sessionState.duration,
    
    // Actions
    startCall,
    endCall,
    submitResponse,
    
    // Loading states
    isStarting: startCallMutation.isPending,
    isEnding: endCallMutation.isPending,
    isSubmitting: submitResponseMutation.isPending,
    
    // Error states
    startError: startCallMutation.error,
    endError: endCallMutation.error,
    submitError: submitResponseMutation.error,
    
    // Utilities
    getActiveSession: getActiveSessionQuery,
    clearErrors: () => {
      startCallMutation.reset()
      endCallMutation.reset()
      submitResponseMutation.reset()
    }
  }
}
```

## 📋 Form Management Hook Template

Use this template for hooks that manage form state and validation.

### Complete Form Hook Template
```typescript
// File: use-lead-form.ts
import { useState, useCallback, useMemo } from 'react'
import type { Lead } from '@/types/lead-types'

interface LeadFormData {
  firstName: string
  lastName: string
  email: string
  phone: string
  company: string
  jobTitle: string
  source: string
  notes: string
}

interface FormErrors {
  firstName?: string
  lastName?: string
  email?: string
  phone?: string
  company?: string
  jobTitle?: string
  source?: string
}

interface UseLeadFormOptions {
  initialData?: Partial<Lead>
  validateOnChange?: boolean
  onSubmit?: (data: LeadFormData) => void | Promise<void>
}

export const useLeadForm = (options: UseLeadFormOptions = {}) => {
  const { initialData, validateOnChange = false, onSubmit } = options

  // Form data state
  const [formData, setFormData] = useState<LeadFormData>({
    firstName: initialData?.first_name || '',
    lastName: initialData?.last_name || '',
    email: initialData?.email || '',
    phone: initialData?.phone || '',
    company: initialData?.company || '',
    jobTitle: initialData?.job_title || '',
    source: initialData?.source || '',
    notes: initialData?.notes || ''
  })

  // Form state
  const [errors, setErrors] = useState<FormErrors>({})
  const [isDirty, setIsDirty] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)

  // Validation rules
  const validateField = useCallback((field: keyof LeadFormData, value: string): string | undefined => {
    switch (field) {
      case 'firstName':
        if (!value.trim()) return 'First name is required'
        if (value.length < 2) return 'First name must be at least 2 characters'
        break
      case 'lastName':
        if (!value.trim()) return 'Last name is required'
        if (value.length < 2) return 'Last name must be at least 2 characters'
        break
      case 'email':
        if (!value.trim()) return 'Email is required'
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        if (!emailRegex.test(value)) return 'Please enter a valid email address'
        break
      case 'phone':
        if (value && !/^[\+]?[0-9\s\-\(\)]{10,}$/.test(value)) {
          return 'Please enter a valid phone number'
        }
        break
      case 'source':
        if (!value.trim()) return 'Lead source is required'
        break
    }
    return undefined
  }, [])

  // Validate entire form
  const validateForm = useCallback((): boolean => {
    const newErrors: FormErrors = {}
    
    Object.keys(formData).forEach((key) => {
      const field = key as keyof LeadFormData
      const error = validateField(field, formData[field])
      if (error) {
        newErrors[field] = error
      }
    })
    
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }, [formData, validateField])

  // Update field value
  const updateField = useCallback((field: keyof LeadFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    setIsDirty(true)
    setSubmitError(null)
    
    // Clear error for this field
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }))
    }
    
    // Validate on change if enabled
    if (validateOnChange) {
      const error = validateField(field, value)
      if (error) {
        setErrors(prev => ({ ...prev, [field]: error }))
      }
    }
  }, [errors, validateOnChange, validateField])

  // Update multiple fields at once
  const updateFields = useCallback((updates: Partial<LeadFormData>) => {
    setFormData(prev => ({ ...prev, ...updates }))
    setIsDirty(true)
    setSubmitError(null)
  }, [])

  // Reset form
  const resetForm = useCallback(() => {
    setFormData({
      firstName: initialData?.first_name || '',
      lastName: initialData?.last_name || '',
      email: initialData?.email || '',
      phone: initialData?.phone || '',
      company: initialData?.company || '',
      jobTitle: initialData?.job_title || '',
      source: initialData?.source || '',
      notes: initialData?.notes || ''
    })
    setErrors({})
    setIsDirty(false)
    setIsSubmitting(false)
    setSubmitError(null)
  }, [initialData])

  // Handle form submission
  const handleSubmit = useCallback(async (e?: React.FormEvent) => {
    if (e) {
      e.preventDefault()
    }
    
    if (!validateForm()) {
      return false
    }
    
    if (!onSubmit) {
      return true
    }
    
    setIsSubmitting(true)
    setSubmitError(null)
    
    try {
      await onSubmit(formData)
      setIsDirty(false)
      return true
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : 'An error occurred')
      return false
    } finally {
      setIsSubmitting(false)
    }
  }, [formData, validateForm, onSubmit])

  // Computed values
  const isValid = useMemo(() => {
    return Object.keys(errors).length === 0 && 
           formData.firstName.trim() !== '' && 
           formData.lastName.trim() !== '' && 
           formData.email.trim() !== ''
  }, [errors, formData])

  const hasChanges = useMemo(() => {
    if (!initialData) return isDirty
    
    return (
      formData.firstName !== (initialData.first_name || '') ||
      formData.lastName !== (initialData.last_name || '') ||
      formData.email !== (initialData.email || '') ||
      formData.phone !== (initialData.phone || '') ||
      formData.company !== (initialData.company || '') ||
      formData.jobTitle !== (initialData.job_title || '') ||
      formData.source !== (initialData.source || '') ||
      formData.notes !== (initialData.notes || '')
    )
  }, [formData, initialData, isDirty])

  return {
    // Form data
    formData,
    errors,
    submitError,
    
    // Form state
    isDirty,
    isSubmitting,
    isValid,
    hasChanges,
    
    // Actions
    updateField,
    updateFields,
    validateForm,
    resetForm,
    handleSubmit,
    
    // Utilities
    clearErrors: () => setErrors({}),
    clearSubmitError: () => setSubmitError(null),
    setFieldError: (field: keyof FormErrors, error: string) => {
      setErrors(prev => ({ ...prev, [field]: error }))
    }
  }
}
```

## 🔄 State Management Hook Template

Use this template for hooks that manage complex local state.

### Complete State Management Hook Template
```typescript
// File: use-lead-dashboard-state.ts
import { useState, useCallback, useMemo } from 'react'
import type { Lead, LeadStatus } from '@/types/lead-types'

interface DashboardFilters {
  statusId?: number
  assignedTo?: string
  source?: string
  dateRange?: {
    start: string
    end: string
  }
  searchTerm?: string
}

interface DashboardView {
  type: 'list' | 'kanban' | 'calendar'
  sortBy: 'created_at' | 'updated_at' | 'first_name'
  sortOrder: 'asc' | 'desc'
  pageSize: number
  currentPage: number
}

interface SelectedItems {
  leads: string[]
  activities: string[]
}

export const useLeadDashboardState = () => {
  // Filter state
  const [filters, setFilters] = useState<DashboardFilters>({})
  
  // View state
  const [view, setView] = useState<DashboardView>({
    type: 'list',
    sortBy: 'created_at',
    sortOrder: 'desc',
    pageSize: 25,
    currentPage: 1
  })
  
  // Selection state
  const [selectedItems, setSelectedItems] = useState<SelectedItems>({
    leads: [],
    activities: []
  })
  
  // UI state
  const [isFilterPanelOpen, setIsFilterPanelOpen] = useState(false)
  const [activeModal, setActiveModal] = useState<string | null>(null)
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)

  // Filter management
  const updateFilter = useCallback((key: keyof DashboardFilters, value: any) => {
    setFilters(prev => ({ ...prev, [key]: value }))
    // Reset to first page when filtering
    setView(prev => ({ ...prev, currentPage: 1 }))
  }, [])

  const clearFilters = useCallback(() => {
    setFilters({})
    setView(prev => ({ ...prev, currentPage: 1 }))
  }, [])

  const resetFilters = useCallback(() => {
    setFilters({
      statusId: undefined,
      assignedTo: undefined,
      source: undefined,
      dateRange: undefined,
      searchTerm: ''
    })
    setView(prev => ({ ...prev, currentPage: 1 }))
  }, [])

  // View management
  const changeView = useCallback((newView: Partial<DashboardView>) => {
    setView(prev => ({ ...prev, ...newView, currentPage: 1 }))
  }, [])

  const changePage = useCallback((page: number) => {
    setView(prev => ({ ...prev, currentPage: page }))
  }, [])

  const changeSort = useCallback((sortBy: DashboardView['sortBy'], sortOrder?: DashboardView['sortOrder']) => {
    setView(prev => ({ 
      ...prev, 
      sortBy, 
      sortOrder: sortOrder || (prev.sortBy === sortBy && prev.sortOrder === 'asc' ? 'desc' : 'asc'),
      currentPage: 1 
    }))
  }, [])

  // Selection management
  const selectLead = useCallback((leadId: string) => {
    setSelectedItems(prev => ({
      ...prev,
      leads: prev.leads.includes(leadId) 
        ? prev.leads.filter(id => id !== leadId)
        : [...prev.leads, leadId]
    }))
  }, [])

  const selectAllLeads = useCallback((leadIds: string[]) => {
    setSelectedItems(prev => ({
      ...prev,
      leads: prev.leads.length === leadIds.length ? [] : leadIds
    }))
  }, [])

  const clearSelection = useCallback(() => {
    setSelectedItems({
      leads: [],
      activities: []
    })
  }, [])

  // Modal management
  const openModal = useCallback((modalType: string) => {
    setActiveModal(modalType)
  }, [])

  const closeModal = useCallback(() => {
    setActiveModal(null)
  }, [])

  // Computed values
  const hasActiveFilters = useMemo(() => {
    return Object.values(filters).some(value => {
      if (value === undefined || value === null || value === '') return false
      if (typeof value === 'object' && 'start' in value) {
        return value.start !== '' || value.end !== ''
      }
      return true
    })
  }, [filters])

  const selectedLeadsCount = useMemo(() => selectedItems.leads.length, [selectedItems.leads])

  const hasSelection = useMemo(() => selectedLeadsCount > 0, [selectedLeadsCount])

  // URL state management (optional)
  const getStateAsUrlParams = useCallback(() => {
    const params = new URLSearchParams()
    
    if (filters.statusId) params.set('status', filters.statusId.toString())
    if (filters.assignedTo) params.set('assigned', filters.assignedTo)
    if (filters.source) params.set('source', filters.source)
    if (filters.searchTerm) params.set('search', filters.searchTerm)
    if (view.type !== 'list') params.set('view', view.type)
    if (view.sortBy !== 'created_at') params.set('sort', view.sortBy)
    if (view.sortOrder !== 'desc') params.set('order', view.sortOrder)
    if (view.currentPage > 1) params.set('page', view.currentPage.toString())
    
    return params.toString()
  }, [filters, view])

  const loadStateFromUrlParams = useCallback((params: URLSearchParams) => {
    const newFilters: DashboardFilters = {}
    const newView: Partial<DashboardView> = {}
    
    const status = params.get('status')
    if (status) newFilters.statusId = parseInt(status)
    
    const assigned = params.get('assigned')
    if (assigned) newFilters.assignedTo = assigned
    
    const source = params.get('source')
    if (source) newFilters.source = source
    
    const search = params.get('search')
    if (search) newFilters.searchTerm = search
    
    const viewType = params.get('view') as DashboardView['type']
    if (viewType) newView.type = viewType
    
    const sortBy = params.get('sort') as DashboardView['sortBy']
    if (sortBy) newView.sortBy = sortBy
    
    const sortOrder = params.get('order') as DashboardView['sortOrder']
    if (sortOrder) newView.sortOrder = sortOrder
    
    const page = params.get('page')
    if (page) newView.currentPage = parseInt(page)
    
    setFilters(prev => ({ ...prev, ...newFilters }))
    setView(prev => ({ ...prev, ...newView }))
  }, [])

  return {
    // State
    filters,
    view,
    selectedItems,
    isFilterPanelOpen,
    activeModal,
    sidebarCollapsed,
    
    // Filter actions
    updateFilter,
    clearFilters,
    resetFilters,
    
    // View actions
    changeView,
    changePage,
    changeSort,
    
    // Selection actions
    selectLead,
    selectAllLeads,
    clearSelection,
    
    // UI actions
    openModal,
    closeModal,
    toggleFilterPanel: () => setIsFilterPanelOpen(prev => !prev),
    toggleSidebar: () => setSidebarCollapsed(prev => !prev),
    
    // Computed values
    hasActiveFilters,
    selectedLeadsCount,
    hasSelection,
    
    // URL state (optional)
    getStateAsUrlParams,
    loadStateFromUrlParams
  }
}
```

## 🎯 Hook Naming Examples

### Data Management Hooks
- `useLeadManagement`
- `useClientManagement`
- `useConsultationManagement`
- `useActivityTracking`
- `useUserProfiles`

### Feature-Specific Hooks
- `useCallSession`
- `useConsultationBooking`
- `useSmsCampaign`
- `useEmailCampaign`
- `useLeadStatusUpdate`

### Form Management Hooks
- `useLeadForm`
- `useConsultationForm`
- `useCallScriptForm`
- `useContactForm`
- `useUserProfileForm`

### State Management Hooks
- `useLeadDashboardState`
- `useCallControlsState`
- `useModalState`
- `useFilterState`
- `useSelectionState`

### Utility Hooks
- `useDebounce`
- `useLocalStorage`
- `usePermissions`
- `useNotifications`
- `useTimer`

## 📋 Hook Return Object Pattern

Always return a well-organized object with clear groupings:

```typescript
return {
  // 1. Data (most important first)
  items,
  selectedItem,
  currentUser,
  
  // 2. Loading states
  isLoading,
  isCreating,
  isUpdating,
  isDeleting,
  
  // 3. Actions (verbs)
  createItem,
  updateItem,
  deleteItem,
  selectItem,
  
  // 4. Error states
  error,
  createError,
  updateError,
  deleteError,
  
  // 5. Computed values
  isValid,
  hasChanges,
  canSubmit,
  
  // 6. Utilities (last)
  refetch,
  reset,
  clearErrors,
}
```

## 🔧 Best Practices

1. **Use TypeScript interfaces** for all data structures
2. **Group related functionality** in the return object
3. **Provide clear loading states** for async operations
4. **Handle errors gracefully** and expose them appropriately
5. **Use useCallback and useMemo** for performance optimization
6. **Follow React Query patterns** for data fetching
7. **Implement proper cleanup** in useEffect hooks
8. **Use descriptive names** that explain the hook's purpose
9. **Keep hooks focused** on a single responsibility
10. **Document complex logic** with comments
