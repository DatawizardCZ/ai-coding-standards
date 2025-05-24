# Naming Conventions - Quick Reference

> **For AI Tools**: This is the condensed version optimized for knowledge bases and AI prompts

## 🚀 Essential Rules

### Files & Directories
- **All files**: `kebab-case`
- **All directories**: `kebab-case`

```
✅ lead-interaction-dashboard.tsx
✅ use-lead-management.ts  
✅ schedule-consultation-modal.tsx
✅ components/lead/
✅ hooks/use-leads/

❌ LeadDashboard.tsx
❌ useLeadManagement.ts
❌ components/Lead/
```

### Components
- **Component names**: `PascalCase`, descriptive and feature-specific

```typescript
✅ export const LeadInteractionDashboard = () => {}
✅ export const ScheduleConsultationModal = () => {}
✅ export const CallScriptQuestionForm = () => {}

❌ export const Dashboard = () => {}
❌ export const Modal = () => {}
❌ export const Form = () => {}
```

### Hooks
- **Hook names**: `camelCase` starting with "use"
- **Files**: `kebab-case` starting with "use"

```typescript
✅ export const useLeadManagement = () => {}
✅ export const useCallSession = () => {}
✅ export const useConsultationBooking = () => {}

// File names:
✅ use-lead-management.ts
✅ use-call-session.ts

❌ export const useData = () => {}
❌ export const useAPI = () => {}
```

### Props & Interfaces
- **Interfaces**: `PascalCase` with descriptive suffix
- **Props**: `camelCase`
- **Event handlers**: `"on"` + action
- **Boolean props**: `"is"` or `"has"` prefix

```typescript
✅ interface LeadCardProps {
  leadId: string
  isSelected: boolean
  isLoading: boolean
  onLeadSelect: (id: string) => void
  onCallStart: () => void
  onStatusUpdate: (statusId: number) => void
}

❌ interface Props {
  data: any
  selected: boolean
  click: () => void
}
```

### Variables & Functions
- **Variables**: `camelCase`, descriptive
- **Functions**: `camelCase`, verb-based
- **Event handlers**: `handle` + action

```typescript
✅ const leadId = "uuid"
✅ const currentCallSession = {}
✅ const isConsultationScheduled = true
✅ const handleCallStart = () => {}
✅ const updateLeadStatus = () => {}

❌ const data = {}
❌ const doSomething = () => {}
```

### Constants
- **Constants**: `SCREAMING_SNAKE_CASE`

```typescript
✅ const LEAD_STATUS = {
  NEW: 'new',
  CONTACTED: 'contacted',
  QUALIFIED: 'qualified'
} as const

✅ const CALL_OUTCOMES = {
  NO_ANSWER: 'no_answer',
  NO_TIME: 'no_time',
  HAS_TIME: 'has_time'
} as const
```

### Database Types
- **Tables**: `snake_case` (PostgreSQL style)
- **TypeScript interfaces**: `PascalCase`
- **Fields**: `snake_case` (matching DB)

```typescript
✅ interface Lead {
  id: string
  first_name: string
  last_name: string
  current_status_id: number
}

✅ Database tables: leads, lead_status, lead_activity, call_script_template

❌ interface lead {
  firstName: string  // Should match DB field names
}
```

## 🎯 Project Structure
```
components/
├── lead/           # Lead management components
├── client/         # Client management components  
├── dashboard/      # Dashboard components
├── common/         # Shared business components
└── ui/            # UI library components

hooks/
├── use-leads/      # Lead-related hooks
├── use-auth/       # Authentication hooks
└── use-analytics/  # Analytics hooks
```

## 🎨 Component Naming Examples

### Modal Components
- `ScheduleConsultationModal`
- `AddToSmsCampaignModal` 
- `AddToEmailCampaignModal`
- `CloseLeadModal`

### Form Components
- `LeadContactForm`
- `CallScriptQuestionForm`
- `ConsultationBookingForm`

### Display Components  
- `LeadActivityTimeline`
- `CallControlsPanel`
- `LeadStatsCard`

### Hook Examples
- `useLeadManagement`
- `useCallSession`
- `useConsultationBooking`
- `useActivityTracking`

## ⚡ Quick Validation Checklist
1. ✅ File names are kebab-case
2. ✅ Component names are PascalCase  
3. ✅ Hooks start with "use" and are camelCase
4. ✅ Props use "on" prefix for event handlers
5. ✅ Constants are SCREAMING_SNAKE_CASE
6. ✅ Database fields use snake_case pattern
