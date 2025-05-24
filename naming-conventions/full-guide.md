# Naming Conventions - Full Guide

## 📋 Table of Contents
- [Overview](#overview)
- [File & Directory Naming](#file--directory-naming)
- [Component Naming](#component-naming)
- [Hook Naming](#hook-naming)
- [Variable & Function Naming](#variable--function-naming)
- [Props & Interface Naming](#props--interface-naming)
- [Constants & Enums](#constants--enums)
- [Database Integration](#database-integration)
- [CSS & Styling](#css--styling)
- [Import/Export Conventions](#importexport-conventions)
- [Project Organization](#project-organization)

## Overview

This guide establishes naming conventions for React/TypeScript applications with Supabase backend, optimized for AI-assisted development and team collaboration.

### Key Principles
- **Consistency**: Same patterns across entire codebase
- **Clarity**: Names should be self-documenting
- **AI-Friendly**: Patterns that AI tools can easily follow
- **Scalability**: Conventions that work as project grows

## File & Directory Naming

### Files
- **Always use kebab-case**
- **Be descriptive and specific**
- **Include component type in name**

```
✅ Good Examples:
lead-interaction-dashboard.tsx
schedule-consultation-modal.tsx
use-lead-management.ts
call-script-question-form.tsx
lead-activity-timeline.tsx

❌ Bad Examples:
LeadDashboard.tsx
Modal.tsx
useLeadManagement.ts
form.tsx
component.tsx
```

### Directories
- **Always use kebab-case**
- **Feature-based organization**
- **Descriptive folder names**

```
✅ Good Examples:
components/lead/
components/client/
hooks/use-leads/
pages/dashboard/
lib/supabase/

❌ Bad Examples:
components/Lead/
Components/
hooks/leadHooks/
pages/Dashboard/
```

## Component Naming

### Component Names
- **Always use PascalCase**
- **Include feature and component type**
- **Be specific, avoid generic names**

```typescript
✅ Good Examples:
export const LeadInteractionDashboard = () => {}
export const ScheduleConsultationModal = () => {}
export const CallScriptQuestionForm = () => {}
export const ActivityTimelineItem = () => {}
export const LeadStatusDropdown = () => {}

❌ Bad Examples:
export const Dashboard = () => {}
export const Modal = () => {}
export const Form = () => {}
export const Item = () => {}
export const Dropdown = () => {}
```

### Component File Structure
```typescript
// ✅ Simple component
// File: lead-interaction-dashboard.tsx
export const LeadInteractionDashboard = () => {
  // Component logic
}

// ✅ Complex component with sub-components
// File: lead-interaction-dashboard.tsx
export const LeadInteractionDashboard = {
  Root: LeadInteractionDashboardRoot,
  Header: LeadInteractionHeader,
  ActivityPanel: ActivityPanel,
  CallControls: CallControls,
  QuestionModule: QuestionModule,
}
```

## Hook Naming

### Custom Hooks
- **Always start with "use"**
- **Use camelCase**
- **Be descriptive of functionality**

```typescript
✅ Good Examples:
export const useLeadManagement = () => {}
export const useCallSession = () => {}
export const useConsultationBooking = () => {}
export const useActivityTracking = () => {}
export const useLeadStatusUpdate = () => {}

// React Query specific hooks
export const useLeadsQuery = () => {}
export const useCreateLeadMutation = () => {}
export const useUpdateLeadStatusMutation = () => {}

❌ Bad Examples:
export const useData = () => {}
export const useAPI = () => {}
export const useStuff = () => {}
export const leadManagement = () => {} // Missing "use"
```

### Hook Files
- **Start with "use-" in kebab-case**
- **Match the hook name pattern**

```
✅ Good Examples:
use-lead-management.ts → useLeadManagement
use-call-session.ts → useCallSession
use-consultation-booking.ts → useConsultationBooking

❌ Bad Examples:
leadManagement.ts
hooks.ts
api.ts
```

## Variable & Function Naming

### Variables
- **Use camelCase**
- **Be descriptive and context-specific**
- **Use meaningful names that explain purpose**

```typescript
✅ Good Examples:
const leadId = "uuid-string"
const currentCallSession = { ... }
const isConsultationScheduled = true
const selectedQuestionIndex = 2
const callDurationMinutes = 15
const hasUnsavedChanges = false

❌ Bad Examples:
const data = { ... }
const info = { ... }
const temp = { ... }
const x = 2
const flag = false
```

### Functions
- **Use camelCase**
- **Start with verb that describes action**
- **Be specific about what the function does**

```typescript
✅ Good Examples:
const handleCallStart = () => {}
const updateLeadStatus = () => {}
const scheduleConsultation = () => {}
const validatePhoneNumber = () => {}
const formatCallDuration = () => {}
const calculateSessionLength = () => {}

// Event handlers
const handleLeadSelect = () => {}
const handleModalClose = () => {}
const handleQuestionSubmit = () => {}
const handleFormChange = () => {}

❌ Bad Examples:
const doSomething = () => {}
const process = () => {}
const handle = () => {}
const click = () => {}
const change = () => {}
```

## Props & Interface Naming

### Interface Names
- **Use PascalCase**
- **Include descriptive suffix**
- **Be specific about component/feature**

```typescript
✅ Good Examples:
interface LeadCardProps { ... }
interface ScheduleConsultationModalProps { ... }
interface CallSessionHookReturn { ... }
interface ApiResponse<T> { ... }
interface DatabaseConfig { ... }

❌ Bad Examples:
interface Props { ... }
interface Config { ... }
interface Data { ... }
interface Response { ... }
```

### Props Naming
- **Use camelCase**
- **Use "on" prefix for event handlers**
- **Use "is/has/can/should" prefix for booleans**

```typescript
✅ Good Examples:
interface LeadCardProps {
  leadId: string
  lead: Lead
  isSelected: boolean
  isLoading: boolean
  hasUnsavedChanges: boolean
  canEdit: boolean
  shouldHighlight: boolean
  
  // Event handlers
  onLeadSelect: (leadId: string) => void
  onCallStart: (leadId: string) => void
  onStatusUpdate: (leadId: string, statusId: number) => void
  onEdit: () => void
  onDelete: () => void
}

❌ Bad Examples:
interface Props {
  data: any
  selected: boolean
  loading: boolean
  click: () => void
  change: () => void
  update: (x: any) => void
}
```

## Constants & Enums

### Constants
- **Use SCREAMING_SNAKE_CASE**
- **Group related constants in objects**
- **Use `as const` for type safety**

```typescript
✅ Good Examples:
export const LEAD_STATUS = {
  NEW: 'new',
  CONTACTED: 'contacted',
  QUALIFIED: 'qualified',
  CONSULTATION_SCHEDULED: 'consultation_scheduled',
  WON: 'won',
  LOST: 'lost'
} as const

export const CALL_OUTCOMES = {
  NO_ANSWER: 'no_answer',
  NO_TIME: 'no_time',
  HAS_TIME: 'has_time'
} as const

export const API_ENDPOINTS = {
  LEADS: '/api/leads',
  CALL_SESSIONS: '/api/call-sessions',
  CONSULTATIONS: '/api/consultations'
} as const

❌ Bad Examples:
const leadStatus = { ... }
const LEADSTATUS = { ... }
const lead_status = { ... }
```

### TypeScript Enums
- **Use PascalCase for enum names**
- **Use PascalCase for enum values**

```typescript
✅ Good Examples:
export enum CallScriptType {
  Initial = 'initial',
  Qualification = 'qualification',
  FollowUp = 'follow_up'
}

export enum LeadSource {
  Website = 'website',
  Referral = 'referral',
  SocialMedia = 'social_media',
  AdCampaign = 'ad_campaign'
}

❌ Bad Examples:
enum callScriptType { ... }
enum LEAD_SOURCE { ... }
```

## Database Integration

### Database Tables
- **Use snake_case (PostgreSQL convention)**
- **Use plural for entity tables**

```sql
✅ Good Examples:
leads
lead_status
lead_activity
lead_call_session
call_script_template
call_script_question

❌ Bad Examples:
Lead
leadStatus
leadactivity
LeadCallSession
```

### TypeScript Interfaces for Database
- **Use PascalCase for interface names**
- **Use snake_case for field names (matching database)**

```typescript
✅ Good Examples:
export interface Lead {
  id: string
  first_name: string
  last_name: string
  email: string
  phone?: string
  current_status_id: number
  created_at: string
  updated_at: string
}

export interface LeadStatus {
  id: number
  code: string
  name_cs: string
  name_en: string
  is_active: boolean
  created_at: string
}

// Database row types
export type LeadRow = Database['public']['Tables']['leads']['Row']
export type LeadInsert = Database['public']['Tables']['leads']['Insert']
export type LeadUpdate = Database['public']['Tables']['leads']['Update']

❌ Bad Examples:
interface lead { ... } // Should be PascalCase
interface Lead {
  firstName: string // Should be first_name to match DB
  lastName: string  // Should be last_name to match DB
}
```

### API Functions
- **Use camelCase with clear action verbs**

```typescript
✅ Good Examples:
export const createLead = async (data: LeadInsert) => { ... }
export const updateLeadStatus = async (leadId: string, statusId: number) => { ... }
export const getLeadActivities = async (leadId: string) => { ... }
export const scheduleCallSession = async (data: CallSessionInsert) => { ... }
export const deleteLeadNote = async (noteId: string) => { ... }

❌ Bad Examples:
export const leadAPI = async () => { ... }
export const doUpdate = async () => { ... }
export const getData = async () => { ... }
```

## CSS & Styling

### Custom CSS Classes
- **Use kebab-case**
- **Follow BEM methodology for complex components**

```css
✅ Good Examples:
.lead-interaction-dashboard { ... }
.call-controls-panel { ... }
.question-module__header { ... }
.question-module__item--active { ... }
.lead-status--new { ... }
.lead-status--qualified { ... }

❌ Bad Examples:
.LeadDashboard { ... }
.callControls { ... }
.item { ... }
```

### CSS Custom Properties
- **Use kebab-case with semantic naming**

```css
✅ Good Examples:
:root {
  --color-primary-red: #E63946;
  --color-accent-green: #1DB954;
  --color-secondary-charcoal: #333A45;
  --color-text-light-gray: #F5F5F5;
  
  --spacing-component-gap: 1.5rem;
  --border-radius-modal: 0.75rem;
  --transition-standard: 200ms ease-in-out;
}

❌ Bad Examples:
:root {
  --primaryColor: #E63946;
  --green: #1DB954;
  --spacing1: 1.5rem;
}
```

## Import/Export Conventions

### Named Exports
- **Prefer named exports for better tree-shaking**

```typescript
✅ Good Examples:
export { LeadInteractionDashboard }
export { useLeadManagement }
export { LEAD_STATUS }

// For index files
export { LeadInteractionDashboard } from './lead-interaction-dashboard'
export { CallControls } from './call-controls'
export { QuestionModule } from './question-module'

❌ Bad Examples:
export default LeadInteractionDashboard // Use sparingly
```

### Import Organization
- **Group imports logically**
- **Consistent ordering**

```typescript
✅ Good Examples:
// React and core libraries
import React from 'react'
import { useState, useEffect } from 'react'

// Third-party libraries
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'

// Internal components and hooks
import { Button } from '@/components/ui/button'
import { useLeadManagement } from '@/hooks/use-lead-management'

// Types and constants
import type { Lead } from '@/types/lead-types'
import { LEAD_STATUS } from '@/constants/lead-constants'

❌ Bad Examples:
// Mixed order, no grouping
import { LEAD_STATUS } from '@/constants/lead-constants'
import React from 'react'
import { Button } from '@/components/ui/button'
import { useQuery } from '@tanstack/react-query'
```

## Project Organization

### Directory Structure
```
src/
├── components/
│   ├── lead/               # Lead-specific components
│   ├── client/             # Client-specific components
│   ├── dashboard/          # Dashboard components
│   ├── common/             # Shared business components
│   └── ui/                 # UI library components
├── hooks/
│   ├── use-leads/          # Lead-related hooks
│   ├── use-auth/           # Authentication hooks
│   └── use-analytics/      # Analytics hooks
├── pages/
│   ├── dashboard/          # Dashboard pages
│   ├── leads/              # Lead management pages
│   └── settings/           # Settings pages
├── lib/
│   ├── supabase/           # Supabase utilities
│   ├── utils/              # General utilities
│   └── validations/        # Form validations
├── types/
│   ├── lead-types.ts       # Lead-related types
│   ├── database-types.ts   # Database types
│   └── api-types.ts        # API response types
└── constants/
    ├── lead-constants.ts   # Lead-related constants
    ├── api-constants.ts    # API constants
    └── ui-constants.ts     # UI constants
```

### Feature-Based Organization
- **Group by business domain, not by file type**
- **Keep related files together**
- **Clear separation of concerns**

```
✅ Good Examples:
components/lead/
├── lead-card.tsx
├── lead-form.tsx
├── lead-modal.tsx
└── lead-timeline.tsx

hooks/
├── use-lead-management.ts
├── use-lead-status.ts
└── use-lead-activities.ts

❌ Bad Examples:
components/
├── cards/
│   └── lead-card.tsx
├── forms/
│   └── lead-form.tsx
└── modals/
    └── lead-modal.tsx
```
