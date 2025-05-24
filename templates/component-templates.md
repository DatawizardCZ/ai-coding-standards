# Component Templates

## 🎯 Modal Component Template

Use this template for all modal components in the application.

### File Structure
```
File: {feature-name}-modal.tsx
Location: /components/{feature}/
Component: {FeatureName}Modal
Props: {FeatureName}ModalProps
```

### Complete Modal Template
```typescript
// File: example-feature-modal.tsx
import React, { useState } from 'react'

interface ExampleFeatureModalProps {
  isOpen: boolean
  leadId: string
  onClose: () => void
  onConfirm: (data: ExampleData) => void
  isLoading?: boolean
}

interface ExampleData {
  // Define your data structure here
  selectedOption: string
  notes?: string
}

export const ExampleFeatureModal = ({ 
  isOpen, 
  leadId, 
  onClose, 
  onConfirm,
  isLoading = false
}: ExampleFeatureModalProps) => {
  const [formData, setFormData] = useState<ExampleData>({
    selectedOption: '',
    notes: ''
  })

  const handleSubmit = () => {
    onConfirm(formData)
  }

  if (!isOpen) return null

  return (
    {/* Modal Overlay */}
    <div className="fixed inset-0 bg-[#333A45]/50 flex items-center justify-center z-50">
      {/* Modal Container */}
      <div className="bg-white rounded-xl shadow-xl w-[800px] max-h-[90vh] flex flex-col">
        
        {/* Header */}
        <div className="px-6 py-4 border-b border-[#D4D4D4] flex justify-between items-center">
          <div className="flex items-center gap-3">
            <i className="fa-solid fa-icon-name text-[#1D3557] text-xl"></i>
            <h2 className="text-xl font-medium text-[#333A45]">Modal Title</h2>
          </div>
          <button 
            onClick={onClose}
            className="text-[#5D6579] hover:text-[#333A45]"
            disabled={isLoading}
          >
            <i className="fa-solid fa-xmark text-xl"></i>
          </button>
        </div>

        {/* Lead Info Section (if applicable) */}
        <div className="sticky top-0 bg-[#F5F5F5] px-6 py-3 border-b border-[#D4D4D4] flex items-center justify-between">
          <div className="flex items-center gap-4">
            <img 
              src="https://storage.googleapis.com/uxpilot-auth.appspot.com/avatars/avatar-2.jpg" 
              className="w-10 h-10 rounded-full" 
              alt="Lead Avatar"
            />
            <div>
              <h3 className="text-[#333A45] font-medium">Lead Name</h3>
              <div className="flex items-center gap-2">
                <span className="bg-[#1DB954] text-white text-xs px-2 py-0.5 rounded">Status</span>
                <span className="text-sm text-[#5D6579]">Additional Info</span>
              </div>
            </div>
          </div>
        </div>

        {/* Body */}
        <div className="p-6 space-y-6 overflow-y-auto">
          {/* Main Content Area */}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[#333A45] mb-2">
                Field Label
              </label>
              <select 
                value={formData.selectedOption}
                onChange={(e) => setFormData(prev => ({ ...prev, selectedOption: e.target.value }))}
                className="w-full p-3 border border-[#D4D4D4] rounded-md appearance-none bg-white"
                disabled={isLoading}
              >
                <option value="">Select option...</option>
                <option value="option1">Option 1</option>
                <option value="option2">Option 2</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-[#333A45] mb-2">
                Notes (Optional)
              </label>
              <textarea 
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                className="w-full p-3 border border-[#D4D4D4] rounded-md h-24 resize-none"
                placeholder="Add any additional notes..."
                disabled={isLoading}
              />
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-[#D4D4D4] flex justify-end gap-3 bg-white">
          <button 
            onClick={onClose}
            className="px-4 py-2 border border-[#D4D4D4] rounded-md hover:bg-[#F5F5F5] disabled:opacity-50"
            disabled={isLoading}
          >
            Cancel
          </button>
          <button 
            onClick={handleSubmit}
            className="px-4 py-2 bg-[#E63946] text-white rounded-md hover:bg-[#EC5766] disabled:opacity-50 flex items-center gap-2"
            disabled={isLoading || !formData.selectedOption}
          >
            {isLoading && <i className="fa-solid fa-spinner fa-spin"></i>}
            <i className="fa-solid fa-check mr-2"></i>
            Confirm Action
          </button>
        </div>
      </div>
    </div>
  )
}
```

## 🧩 Standard Component Template

Use this template for regular (non-modal) components.

### File Structure
```
File: {feature-name}-{component-type}.tsx
Location: /components/{feature}/
Component: {FeatureName}{ComponentType}
Props: {FeatureName}{ComponentType}Props
```

### Complete Component Template
```typescript
// File: lead-activity-timeline.tsx
import React from 'react'

interface ActivityItem {
  id: string
  type: string
  description: string
  createdAt: string
  createdBy: string
}

interface LeadActivityTimelineProps {
  leadId: string
  activities: ActivityItem[]
  isLoading?: boolean
  maxItems?: number
  onActivityClick?: (activityId: string) => void
  onLoadMore?: () => void
  className?: string
}

export const LeadActivityTimeline = ({ 
  leadId,
  activities,
  isLoading = false,
  maxItems,
  onActivityClick,
  onLoadMore,
  className = ''
}: LeadActivityTimelineProps) => {
  const displayedActivities = maxItems ? activities.slice(0, maxItems) : activities
  const hasMore = maxItems && activities.length > maxItems

  const handleActivityClick = (activityId: string) => {
    onActivityClick?.(activityId)
  }

  const handleLoadMoreClick = () => {
    onLoadMore?.()
  }

  if (isLoading) {
    return (
      <div className={`space-y-4 ${className}`}>
        {Array.from({ length: 3 }).map((_, index) => (
          <div key={index} className="animate-pulse">
            <div className="flex items-start gap-3 p-4">
              <div className="w-8 h-8 bg-[#D4D4D4] rounded-full"></div>
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-[#D4D4D4] rounded w-3/4"></div>
                <div className="h-3 bg-[#D4D4D4] rounded w-1/2"></div>
              </div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (activities.length === 0) {
    return (
      <div className={`text-center py-8 ${className}`}>
        <i className="fa-solid fa-clock-rotate-left text-[#5D6579] text-3xl mb-3"></i>
        <p className="text-[#5D6579]">No activities yet</p>
        <p className="text-sm text-[#B0B0B0]">Activities will appear here as they happen</p>
      </div>
    )
  }

  return (
    <div className={`space-y-4 ${className}`}>
      {displayedActivities.map((activity) => (
        <div 
          key={activity.id}
          onClick={() => handleActivityClick(activity.id)}
          className="flex items-start gap-3 p-4 border border-[#D4D4D4] rounded-lg hover:shadow-sm cursor-pointer transition-all"
        >
          <div className="w-8 h-8 bg-[#1D3557] rounded-full flex items-center justify-center">
            <i className="fa-solid fa-clock text-white text-sm"></i>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[#333A45] font-medium">{activity.description}</p>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-sm text-[#5D6579]">{activity.createdAt}</span>
              <span className="text-xs text-[#B0B0B0]">•</span>
              <span className="text-sm text-[#5D6579]">{activity.createdBy}</span>
            </div>
          </div>
          <i className="fa-solid fa-chevron-right text-[#B0B0B0]"></i>
        </div>
      ))}

      {hasMore && (
        <button 
          onClick={handleLoadMoreClick}
          className="w-full py-3 text-[#1D3557] hover:bg-[#F5F5F5] rounded-lg transition-colors"
        >
          <i className="fa-solid fa-chevron-down mr-2"></i>
          Load More Activities
        </button>
      )}
    </div>
  )
}
```

## 📋 Form Component Template

Use this template for form components with validation.

### Complete Form Template
```typescript
// File: consultation-booking-form.tsx
import React, { useState } from 'react'

interface FormData {
  consultationType: string
  scheduledDate: string
  duration: number
  notes: string
}

interface FormErrors {
  consultationType?: string
  scheduledDate?: string
  duration?: string
}

interface ConsultationBookingFormProps {
  leadId: string
  initialData?: Partial<FormData>
  onSubmit: (data: FormData) => void
  onCancel: () => void
  isSubmitting?: boolean
}

export const ConsultationBookingForm = ({
  leadId,
  initialData,
  onSubmit,
  onCancel,
  isSubmitting = false
}: ConsultationBookingFormProps) => {
  const [formData, setFormData] = useState<FormData>({
    consultationType: initialData?.consultationType || '',
    scheduledDate: initialData?.scheduledDate || '',
    duration: initialData?.duration || 60,
    notes: initialData?.notes || ''
  })

  const [errors, setErrors] = useState<FormErrors>({})

  const updateField = (field: keyof FormData, value: string | number) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    // Clear error for this field
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }))
    }
  }

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {}

    if (!formData.consultationType) {
      newErrors.consultationType = 'Consultation type is required'
    }

    if (!formData.scheduledDate) {
      newErrors.scheduledDate = 'Date is required'
    } else if (new Date(formData.scheduledDate) <= new Date()) {
      newErrors.scheduledDate = 'Date must be in the future'
    }

    if (formData.duration < 15) {
      newErrors.duration = 'Duration must be at least 15 minutes'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    if (validateForm()) {
      onSubmit(formData)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Consultation Type */}
      <div>
        <label className="block text-sm font-medium text-[#333A45] mb-2">
          Consultation Type *
        </label>
        <select
          value={formData.consultationType}
          onChange={(e) => updateField('consultationType', e.target.value)}
          className={`w-full p-3 border rounded-md appearance-none bg-white ${
            errors.consultationType ? 'border-[#E63946]' : 'border-[#D4D4D4]'
          }`}
          disabled={isSubmitting}
        >
          <option value="">Select consultation type...</option>
          <option value="strategy">Strategy Session</option>
          <option value="technical">Technical Review</option>
          <option value="product">Product Demo</option>
          <option value="discovery">Discovery Call</option>
        </select>
        {errors.consultationType && (
          <p className="text-[#E63946] text-sm mt-1">{errors.consultationType}</p>
        )}
      </div>

      {/* Scheduled Date */}
      <div>
        <label className="block text-sm font-medium text-[#333A45] mb-2">
          Date & Time *
        </label>
        <input
          type="datetime-local"
          value={formData.scheduledDate}
          onChange={(e) => updateField('scheduledDate', e.target.value)}
          className={`w-full p-3 border rounded-md ${
            errors.scheduledDate ? 'border-[#E63946]' : 'border-[#D4D4D4]'
          }`}
          disabled={isSubmitting}
        />
        {errors.scheduledDate && (
          <p className="text-[#E63946] text-sm mt-1">{errors.scheduledDate}</p>
        )}
      </div>

      {/* Duration */}
      <div>
        <label className="block text-sm font-medium text-[#333A45] mb-2">
          Duration (minutes) *
        </label>
        <select
          value={formData.duration}
          onChange={(e) => updateField('duration', Number(e.target.value))}
          className={`w-full p-3 border rounded-md appearance-none bg-white ${
            errors.duration ? 'border-[#E63946]' : 'border-[#D4D4D4]'
          }`}
          disabled={isSubmitting}
        >
          <option value={30}>30 minutes</option>
          <option value={45}>45 minutes</option>
          <option value={60}>60 minutes</option>
          <option value={90}>90 minutes</option>
        </select>
        {errors.duration && (
          <p className="text-[#E63946] text-sm mt-1">{errors.duration}</p>
        )}
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-[#333A45] mb-2">
          Notes (Optional)
        </label>
        <textarea
          value={formData.notes}
          onChange={(e) => updateField('notes', e.target.value)}
          className="w-full p-3 border border-[#D4D4D4] rounded-md h-24 resize-none"
          placeholder="Add any special requirements or notes..."
          disabled={isSubmitting}
        />
      </div>

      {/* Form Actions */}
      <div className="flex justify-end gap-3 pt-4 border-t border-[#D4D4D4]">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border border-[#D4D4D4] rounded-md hover:bg-[#F5F5F5] disabled:opacity-50"
          disabled={isSubmitting}
        >
          Cancel
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-[#E63946] text-white rounded-md hover:bg-[#EC5766] disabled:opacity-50 flex items-center gap-2"
          disabled={isSubmitting}
        >
          {isSubmitting && <i className="fa-solid fa-spinner fa-spin"></i>}
          <i className="fa-solid fa-calendar-check mr-2"></i>
          Book Consultation
        </button>
      </div>
    </form>
  )
}
```

## 🎨 Component Naming Examples

### Modal Components
- `ScheduleConsultationModal`
- `AddToSmsCampaignModal`
- `AddToEmailCampaignModal`
- `CloseLeadModal`
- `EditLeadModal`
- `ConfirmDeleteModal`

### Form Components
- `LeadContactForm`
- `CallScriptQuestionForm`
- `ConsultationBookingForm`
- `LeadStatusUpdateForm`
- `UserProfileForm`

### Display Components
- `LeadActivityTimeline`
- `CallControlsPanel`
- `LeadStatsCard`
- `ConsultationScheduleList`
- `ActivityFilterTabs`

### Interactive Components
- `LeadSelectionDropdown`
- `StatusUpdateDropdown`
- `DateRangePicker`
- `PaginationControls`
- `SearchFilterBar`

## 🎯 Usage Guidelines

1. **Always follow the naming conventions** from `/naming-conventions/`
2. **Use the appropriate template** based on component type
3. **Include proper TypeScript interfaces** for props and data
4. **Handle loading and error states** appropriately
5. **Use project color system** consistently
6. **Include accessibility attributes** when needed
7. **Add proper event handlers** with "on" prefix
8. **Implement form validation** for form components
