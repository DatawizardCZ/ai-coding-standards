# Modal Templates

## 🎯 Standard Modal Template

Use this template for all modal components in the application.

### File Structure
```
File: {feature-name}-modal.tsx
Location: /components/{feature}/
Component: {FeatureName}Modal
Props: {FeatureName}ModalProps
```

### Base Modal Structure
```typescript
// File: base-modal-template.tsx
import React from 'react'

interface BaseModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  icon?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
  showLeadInfo?: boolean
  leadData?: {
    name: string
    status: string
    avatar?: string
  }
  children: React.ReactNode
  footer?: React.ReactNode
}

export const BaseModal = ({
  isOpen,
  onClose,
  title,
  icon,
  size = 'md',
  showLeadInfo = false,
  leadData,
  children,
  footer
}: BaseModalProps) => {
  if (!isOpen) return null

  const sizeClasses = {
    sm: 'w-[400px]',
    md: 'w-[600px]',
    lg: 'w-[800px]',
    xl: 'w-[1000px]'
  }

  return (
    <div className="fixed inset-0 bg-[#333A45]/50 flex items-center justify-center z-50">
      <div className={`bg-white rounded-xl shadow-xl ${sizeClasses[size]} max-h-[90vh] flex flex-col`}>
        
        {/* Header */}
        <div className="px-6 py-4 border-b border-[#D4D4D4] flex justify-between items-center">
          <div className="flex items-center gap-3">
            {icon && <i className={`${icon} text-[#1D3557] text-xl`}></i>}
            <h2 className="text-xl font-medium text-[#333A45]">{title}</h2>
          </div>
          <button 
            onClick={onClose}
            className="text-[#5D6579] hover:text-[#333A45] transition-colors"
          >
            <i className="fa-solid fa-xmark text-xl"></i>
          </button>
        </div>

        {/* Lead Info Section (Optional) */}
        {showLeadInfo && leadData && (
          <div className="sticky top-0 bg-[#F5F5F5] px-6 py-3 border-b border-[#D4D4D4] flex items-center gap-4">
            <img 
              src={leadData.avatar || "https://storage.googleapis.com/uxpilot-auth.appspot.com/avatars/avatar-2.jpg"} 
              className="w-10 h-10 rounded-full" 
              alt="Lead Avatar"
            />
            <div>
              <h3 className="text-[#333A45] font-medium">{leadData.name}</h3>
              <span className="bg-[#1DB954] text-white text-xs px-2 py-0.5 rounded">{leadData.status}</span>
            </div>
          </div>
        )}

        {/* Body */}
        <div className="flex-1 overflow-y-auto">
          {children}
        </div>

        {/* Footer */}
        {footer && (
          <div className="px-6 py-4 border-t border-[#D4D4D4] bg-white">
            {footer}
          </div>
        )}
      </div>
    </div>
  )
}
```

## 📋 Form Modal Template

Use this template for modals that contain forms.

### Complete Form Modal Example
```typescript
// File: schedule-consultation-modal.tsx
import React, { useState } from 'react'
import { BaseModal } from './base-modal-template'

interface ConsultationData {
  consultationType: string
  scheduledDate: string
  duration: number
  notes: string
}

interface ScheduleConsultationModalProps {
  isOpen: boolean
  leadId: string
  leadName: string
  leadStatus: string
  onClose: () => void
  onConfirm: (data: ConsultationData) => Promise<void>
}

export const ScheduleConsultationModal = ({
  isOpen,
  leadId,
  leadName,
  leadStatus,
  onClose,
  onConfirm
}: ScheduleConsultationModalProps) => {
  const [formData, setFormData] = useState<ConsultationData>({
    consultationType: '',
    scheduledDate: '',
    duration: 60,
    notes: ''
  })
  
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {}
    
    if (!formData.consultationType) {
      newErrors.consultationType = 'Consultation type is required'
    }
    
    if (!formData.scheduledDate) {
      newErrors.scheduledDate = 'Date and time is required'
    } else if (new Date(formData.scheduledDate) <= new Date()) {
      newErrors.scheduledDate = 'Date must be in the future'
    }
    
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async () => {
    if (!validateForm()) return
    
    setIsSubmitting(true)
    try {
      await onConfirm(formData)
      onClose()
    } catch (error) {
      console.error('Failed to schedule consultation:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const updateField = (field: keyof ConsultationData, value: string | number) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    // Clear error for this field
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }))
    }
  }

  const modalFooter = (
    <div className="flex justify-end gap-3">
      <button
        onClick={onClose}
        className="px-4 py-2 border border-[#D4D4D4] rounded-md hover:bg-[#F5F5F5] disabled:opacity-50"
        disabled={isSubmitting}
      >
        Cancel
      </button>
      <button
        onClick={handleSubmit}
        className="px-4 py-2 bg-[#E63946] text-white rounded-md hover:bg-[#EC5766] disabled:opacity-50 flex items-center gap-2"
        disabled={isSubmitting || !formData.consultationType || !formData.scheduledDate}
      >
        {isSubmitting && <i className="fa-solid fa-spinner fa-spin"></i>}
        <i className="fa-regular fa-calendar-check mr-2"></i>
        Schedule Consultation
      </button>
    </div>
  )

  return (
    <BaseModal
      isOpen={isOpen}
      onClose={onClose}
      title="Schedule Consultation"
      icon="fa-regular fa-calendar-check"
      size="lg"
      showLeadInfo={true}
      leadData={{
        name: leadName,
        status: leadStatus
      }}
      footer={modalFooter}
    >
      <div className="p-6 space-y-6">
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

        {/* Date and Time */}
        <div className="grid grid-cols-2 gap-6">
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

          <div>
            <label className="block text-sm font-medium text-[#333A45] mb-2">
              Duration
            </label>
            <select
              value={formData.duration}
              onChange={(e) => updateField('duration', Number(e.target.value))}
              className="w-full p-3 border border-[#D4D4D4] rounded-md appearance-none bg-white"
              disabled={isSubmitting}
            >
              <option value={30}>30 minutes</option>
              <option value={45}>45 minutes</option>
              <option value={60}>60 minutes</option>
              <option value={90}>90 minutes</option>
            </select>
          </div>
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
            placeholder="Add any special requirements or agenda items..."
            disabled={isSubmitting}
          />
        </div>
      </div>
    </BaseModal>
  )
}
```

## 🗂️ Selection Modal Template

Use this template for modals that allow selecting from a list of options.

### Complete Selection Modal Example
```typescript
// File: add-to-email-campaign-modal.tsx
import React, { useState } from 'react'
import { BaseModal } from './base-modal-template'

interface EmailCampaign {
  id: string
  name: string
  description: string
  emailCount: number
  duration: string
  type: 'onboarding' | 'nurturing' | 'promotional' | 'reengagement'
}

interface AddToEmailCampaignModalProps {
  isOpen: boolean
  leadId: string
  leadName: string
  leadStatus: string
  campaigns: EmailCampaign[]
  onClose: () => void
  onConfirm: (campaignId: string, startTime?: string) => Promise<void>
}

export const AddToEmailCampaignModal = ({
  isOpen,
  leadId,
  leadName,
  leadStatus,
  campaigns,
  onClose,
  onConfirm
}: AddToEmailCampaignModalProps) => {
  const [selectedCampaignId, setSelectedCampaignId] = useState<string>('')
  const [startTime, setStartTime] = useState<'immediate' | 'scheduled'>('immediate')
  const [scheduledDateTime, setScheduledDateTime] = useState<string>('')
  const [activeTab, setActiveTab] = useState<EmailCampaign['type']>('onboarding')
  const [isSubmitting, setIsSubmitting] = useState(false)

  const filteredCampaigns = campaigns.filter(campaign => campaign.type === activeTab)
  const selectedCampaign = campaigns.find(c => c.id === selectedCampaignId)

  const handleSubmit = async () => {
    if (!selectedCampaignId) return
    
    setIsSubmitting(true)
    try {
      const startDateTime = startTime === 'scheduled' ? scheduledDateTime : undefined
      await onConfirm(selectedCampaignId, startDateTime)
      onClose()
    } catch (error) {
      console.error('Failed to add to campaign:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const campaignTypeIcons = {
    onboarding: 'fa-solid fa-rocket',
    nurturing: 'fa-solid fa-seedling',
    promotional: 'fa-solid fa-tag',
    reengagement: 'fa-solid fa-redo'
  }

  const modalFooter = (
    <div className="flex justify-end gap-3">
      <button
        onClick={onClose}
        className="px-4 py-2 border border-[#D4D4D4] rounded-md hover:bg-[#F5F5F5] disabled:opacity-50"
        disabled={isSubmitting}
      >
        Cancel
      </button>
      <button
        onClick={handleSubmit}
        className="px-4 py-2 bg-[#E63946] text-white rounded-md hover:bg-[#EC5766] disabled:opacity-50 flex items-center gap-2"
        disabled={isSubmitting || !selectedCampaignId}
      >
        {isSubmitting && <i className="fa-solid fa-spinner fa-spin"></i>}
        <i className="fa-solid fa-paper-plane mr-2"></i>
        Add to Campaign
      </button>
    </div>
  )

  return (
    <BaseModal
      isOpen={isOpen}
      onClose={onClose}
      title="Add to Email Campaign"
      icon="fa-solid fa-envelope-circle-check"
      size="lg"
      showLeadInfo={true}
      leadData={{
        name: leadName,
        status: leadStatus
      }}
      footer={modalFooter}
    >
      <div className="p-6 space-y-6">
        {/* Start Time Section */}
        <div>
          <label className="block text-sm font-medium text-[#333A45] mb-2">Start Sending</label>
          <div className="space-y-3">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="start-time"
                checked={startTime === 'immediate'}
                onChange={() => setStartTime('immediate')}
                className="text-[#1D3557]"
              />
              <span>Immediately</span>
            </label>
            <div>
              <label className="flex items-center gap-2 cursor-pointer mb-2">
                <input
                  type="radio"
                  name="start-time"
                  checked={startTime === 'scheduled'}
                  onChange={() => setStartTime('scheduled')}
                  className="text-[#1D3557]"
                />
                <span>Schedule for later</span>
              </label>
              {startTime === 'scheduled' && (
                <div className="ml-6">
                  <input
                    type="datetime-local"
                    value={scheduledDateTime}
                    onChange={(e) => setScheduledDateTime(e.target.value)}
                    className="w-full p-2 border border-[#D4D4D4] rounded-md text-[#333A45] bg-white"
                  />
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Campaign Type Tabs */}
        <div>
          <div className="border-b border-[#D4D4D4]">
            <div className="flex gap-1">
              {(['onboarding', 'nurturing', 'promotional', 'reengagement'] as const).map((type) => (
                <button
                  key={type}
                  onClick={() => setActiveTab(type)}
                  className={`px-4 py-2 font-medium capitalize ${
                    activeTab === type
                      ? 'text-[#1D3557] border-b-2 border-[#1D3557]'
                      : 'text-[#5D6579] hover:text-[#333A45]'
                  }`}
                >
                  <i className={`${campaignTypeIcons[type]} mr-2`}></i>
                  {type}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Campaign Selection Grid */}
        <div className="grid grid-cols-2 gap-4 max-h-96 overflow-y-auto">
          {filteredCampaigns.map((campaign) => (
            <div
              key={campaign.id}
              onClick={() => setSelectedCampaignId(campaign.id)}
              className={`border rounded-lg p-4 cursor-pointer transition-all ${
                selectedCampaignId === campaign.id
                  ? 'border-2 border-[#1D3557] bg-[#F5F5F5]'
                  : 'border border-[#D4D4D4] hover:border-[#1D3557]'
              }`}
            >
              <div className="flex justify-between items-start mb-3">
                <h4 className={`font-medium ${
                  selectedCampaignId === campaign.id ? 'text-[#1D3557]' : 'text-[#333A45]'
                }`}>
                  {campaign.name}
                </h4>
                <span className="bg-[#F5F5F5] text-[#5D6579] text-xs px-2 py-1 rounded">
                  {campaign.emailCount} emails
                </span>
              </div>
              <p className="text-sm text-[#5D6579] mb-3">{campaign.description}</p>
              <div className="flex items-center justify-between">
                <span className="text-xs text-[#5D6579]">{campaign.duration}</span>
                {selectedCampaignId === campaign.id && (
                  <div className="flex items-center text-[#1D3557]">
                    <i className="fa-solid fa-check mr-1"></i>
                    <span className="text-xs font-medium">Selected</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Selected Campaign Summary */}
        {selectedCampaign && (
          <div className="bg-[#F5F5F5] p-4 rounded-lg">
            <h5 className="font-medium text-[#333A45] mb-2">Selected Campaign</h5>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-[#1D3557]">{selectedCampaign.name}</p>
                <p className="text-xs text-[#5D6579]">
                  {selectedCampaign.emailCount} emails • {selectedCampaign.duration}
                </p>
              </div>
              <button
                onClick={() => setSelectedCampaignId('')}
                className="text-[#E63946] hover:text-[#EC5766]"
              >
                <i className="fa-solid fa-times"></i>
              </button>
            </div>
          </div>
        )}
      </div>
    </BaseModal>
  )
}
```

## ⚠️ Confirmation Modal Template

Use this template for confirmation dialogs and destructive actions.

### Complete Confirmation Modal Example
```typescript
// File: close-lead-modal.tsx
import React, { useState } from 'react'
import { BaseModal } from './base-modal-template'

interface CloseReason {
  id: string
  type: 'won' | 'lost'
  label: string
  description: string
}

interface CloseLeadModalProps {
  isOpen: boolean
  leadId: string
  leadName: string
  onClose: () => void
  onConfirm: (reason: string, notes?: string) => Promise<void>
}

const CLOSE_REASONS: CloseReason[] = [
  // Won reasons
  { id: 'direct_purchase', type: 'won', label: 'Direct Purchase', description: 'Lead purchased directly' },
  { id: 'contract_signed', type: 'won', label: 'Contract Signed', description: 'Agreement finalized' },
  { id: 'partnership', type: 'won', label: 'Partnership', description: 'Strategic partnership formed' },
  { id: 'other_win', type: 'won', label: 'Other Win', description: 'Other successful outcome' },
  
  // Lost reasons
  { id: 'no_budget', type: 'lost', label: 'No Budget', description: 'Insufficient budget available' },
  { id: 'no_decision', type: 'lost', label: 'No Decision', description: 'Unable to make decision' },
  { id: 'competitor', type: 'lost', label: 'Chose Competitor', description: 'Selected alternative solution' },
  { id: 'timing', type: 'lost', label: 'Bad Timing', description: 'Not the right time for purchase' },
  { id: 'no_response', type: 'lost', label: 'No Response', description: 'Lead became unresponsive' },
  { id: 'other_lost', type: 'lost', label: 'Other', description: 'Other reason for loss' }
]

export const CloseLeadModal = ({
  isOpen,
  leadId,
  leadName,
  onClose,
  onConfirm
}: CloseLeadModalProps) => {
  const [activeTab, setActiveTab] = useState<'won' | 'lost'>('won')
  const [selectedReason, setSelectedReason] = useState<string>('')
  const [notes, setNotes] = useState<string>('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  const filteredReasons = CLOSE_REASONS.filter(reason => reason.type === activeTab)
  const selectedReasonData = CLOSE_REASONS.find(r => r.id === selectedReason)

  const handleSubmit = async () => {
    if (!selectedReason) return
    
    setIsSubmitting(true)
    try {
      await onConfirm(selectedReason, notes)
      onClose()
    } catch (error) {
      console.error('Failed to close lead:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const modalFooter = (
    <div className="flex justify-end gap-3">
      <button
        onClick={onClose}
        className="px-4 py-2 border border-[#D4D4D4] rounded-md bg-white hover:bg-[#ECECEC] text-[#333A45] disabled:opacity-50"
        disabled={isSubmitting}
      >
        Cancel
      </button>
      <button
        onClick={handleSubmit}
        className="px-4 py-2 bg-[#E63946] text-white rounded-md hover:bg-[#EC5766] disabled:opacity-50 flex items-center gap-2"
        disabled={isSubmitting || !selectedReason}
      >
        {isSubmitting && <i className="fa-solid fa-spinner fa-spin"></i>}
        <i className="fa-solid fa-flag-checkered mr-2"></i>
        Close Lead
      </button>
    </div>
  )

  return (
    <BaseModal
      isOpen={isOpen}
      onClose={onClose}
      title="Close Lead"
      icon="fa-solid fa-flag-checkered"
      size="md"
      footer={modalFooter}
    >
      <div className="p-6 space-y-6">
        {/* Warning Message */}
        <div className="bg-[#FF9999] bg-opacity-20 p-4 rounded-lg flex items-start gap-3">
          <i className="fa-solid fa-triangle-exclamation text-[#E63946] mt-1"></i>
          <div>
            <p className="text-[#333A45] text-sm font-medium">
              You are about to close the lead for "{leadName}"
            </p>
            <p className="text-[#5D6579] text-sm mt-1">
              This action is irreversible. The lead will be marked as closed and removed from active pipeline.
            </p>
          </div>
        </div>

        {/* Outcome Tabs */}
        <div className="flex gap-4 border-b border-[#D4D4D4]">
          <button
            onClick={() => {
              setActiveTab('won')
              setSelectedReason('')
            }}
            className={`px-6 py-3 font-medium ${
              activeTab === 'won'
                ? 'text-[#1DB954] border-b-2 border-[#1DB954]'
                : 'text-[#5D6579] hover:text-[#333A45]'
            }`}
          >
            <i className="fa-solid fa-trophy mr-2"></i>
            Won
          </button>
          <button
            onClick={() => {
              setActiveTab('lost')
              setSelectedReason('')
            }}
            className={`px-6 py-3 font-medium ${
              activeTab === 'lost'
                ? 'text-[#E63946] border-b-2 border-[#E63946]'
                : 'text-[#5D6579] hover:text-[#333A45]'
            }`}
          >
            <i className="fa-solid fa-times mr-2"></i>
            Lost
          </button>
        </div>

        {/* Reason Selection */}
        <div className="grid grid-cols-2 gap-4">
          {filteredReasons.map((reason) => (
            <label key={reason.id} className="cursor-pointer">
              <div
                className={`border rounded-lg p-4 transition-all ${
                  selectedReason === reason.id
                    ? `border-2 ${activeTab === 'won' ? 'border-[#1DB954] bg-green-50' : 'border-[#E63946] bg-red-50'}`
                    : 'border-[#D4D4D4] hover:border-[#1D3557]'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="radio"
                    name="close-reason"
                    value={reason.id}
                    checked={selectedReason === reason.id}
                    onChange={(e) => setSelectedReason(e.target.value)}
                    className="mt-1"
                  />
                  <div>
                    <h3 className="font-medium text-[#333A45]">{reason.label}</h3>
                    <p className="text-sm text-[#5D6579] mt-1">{reason.description}</p>
                  </div>
                </div>
              </div>
            </label>
          ))}
        </div>

        {/* Notes Section */}
        <div>
          <label className="block text-sm font-medium text-[#333A45] mb-2">
            Additional Notes
            {selectedReasonData?.id === 'other_win' || selectedReasonData?.id === 'other_lost' ? ' *' : ' (Optional)'}
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="w-full p-3 border border-[#D4D4D4] rounded-md h-24 resize-none"
            placeholder={
              selectedReasonData?.id === 'other_win' || selectedReasonData?.id === 'other_lost'
                ? 'Please provide details about the outcome...'
                : 'Add any additional context or notes...'
            }
            disabled={isSubmitting}
          />
        </div>

        {/* Selected Reason Summary */}
        {selectedReasonData && (
          <div className={`p-4 rounded-lg ${
            activeTab === 'won' ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'
          }`}>
            <div className="flex items-center gap-2 mb-2">
              <i className={`fa-solid ${activeTab === 'won' ? 'fa-trophy text-[#1DB954]' : 'fa-times text-[#E63946]'}`}></i>
              <span className="font-medium text-[#333A45]">
                Lead will be marked as {activeTab}: {selectedReasonData.label}
              </span>
            </div>
            <p className="text-sm text-[#5D6579]">{selectedReasonData.description}</p>
          </div>
        )}
      </div>
    </BaseModal>
  )
}
```

## 📱 Responsive Modal Considerations

### Mobile Adaptations
```typescript
// Add these classes for mobile responsiveness
const responsiveClasses = {
  container: "w-[90vw] md:w-[800px] max-h-[85vh] md:max-h-[90vh]",
  padding: "p-4 md:p-6",
  grid: "grid-cols-1 md:grid-cols-2",
  text: "text-sm md:text-base"
}

// Example mobile-friendly modal
export const ResponsiveModal = ({ ...props }) => {
  return (
    <div className="fixed inset-0 bg-[#333A45]/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] flex flex-col">
        {/* Content with responsive classes */}
      </div>
    </div>
  )
}
```

## 🎨 Modal Naming Examples

### Action Modals
- `ScheduleConsultationModal`
- `AddToEmailCampaignModal`
- `AddToSmsCampaignModal`
- `SendEmailModal`
- `ScheduleCallModal`

### Confirmation Modals
- `CloseLeadModal`
- `DeleteLeadModal`
- `ConfirmStatusChangeModal`
- `CancelConsultationModal`

### Selection Modals
- `SelectCampaignModal`
- `ChooseTemplateModal`
- `AssignLeadModal`
- `TransferLeadModal`

### Form Modals
- `EditLeadModal`
- `CreateConsultationModal`
- `UpdateStatusModal`
- `AddNoteModal`

## 🔧 Best Practices

1. **Use the BaseModal component** for consistency
2. **Always include proper loading states** during async operations
3. **Implement form validation** for user input
4. **Show clear success/error states** with appropriate styling
5. **Include accessibility attributes** (aria-labels, focus management)
6. **Handle keyboard navigation** (Escape to close, Tab navigation)
7. **Use appropriate modal sizes** based on content
8. **Include lead context** when relevant to the action
9. **Provide clear action buttons** with descriptive labels
10. **Handle edge cases** gracefully (network errors, validation failures)
