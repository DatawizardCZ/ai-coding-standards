# FechtClub Pro - Project Development Guide

## 📋 Project Overview

**Project Name:** FechtClub Pro - Fitness Studio Management System
**Tech Stack:**
- **Frontend:** React 18.3.1 + TypeScript 5.5.3 + Vite
- **UI Framework:** shadcn/ui components with Tailwind CSS
- **Backend:** Supabase (PostgreSQL + Auth + RLS)
- **State Management:** React Query for server state
- **Routing:** React Router v6

**Purpose:** Comprehensive fitness studio management system handling leads, onboarding processes, client management, and trainer coordination.

**Entity Hierarchy:**
```
Lead → Onboarding → Client
         ↓
    Trainer Assignment
```

---

## 📁 File & Directory Standards

### Naming Conventions

**Files:**
- Components: `kebab-case.tsx` (e.g., `onboarding-layout.tsx`)
- Hooks: `use-kebab-case.ts` (e.g., `use-onboarding.ts`)
- Utils: `kebab-case.ts` (e.g., `date-utils.ts`)
- Types: `kebab-case.ts` (e.g., `onboarding-types.ts`)

**Directories:**
- Always `kebab-case` (e.g., `clients/onboarding/`, `components/ui/`)

**Component Exports:**
- Components: `PascalCase` (e.g., `OnboardingLayout`, `DiagnosticsProgress`)
- Functions/hooks: `camelCase` (e.g., `useOnboarding`, `formatDate`)

### Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── ui/             # shadcn/ui components
│   ├── navigation/     # Navigation components (sidebar, header)
│   ├── onboarding/     # Onboarding-specific components
│   └── trainers/       # Trainer-specific components
├── hooks/              # Custom React hooks
├── lib/                # Utility functions and helpers
├── pages/              # Route components
│   ├── clients/        # Client management pages
│   ├── leads/          # Lead management pages
│   └── trainers/       # Trainer management pages
├── integrations/       # External service integrations
│   └── supabase/       # Supabase client and types
└── config/             # Configuration files

docs/
├── database-current/   # Current database schema and migrations
├── knowledge/          # Reference documentation
└── migration/          # Migration planning documents
```

---

## 🎨 Component Development Patterns

### Component Structure

```typescript
// Standard component template
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";

interface ComponentNameProps {
  requiredProp: string;
  optionalProp?: number;
  onAction?: () => void;
}

export function ComponentName({
  requiredProp,
  optionalProp = 0,
  onAction
}: ComponentNameProps) {
  const { toast } = useToast();
  const [state, setState] = useState<string>("");

  const handleAction = async () => {
    try {
      // Implementation
      onAction?.();

      toast({
        title: "Úspěch",
        description: "Operace byla dokončena",
      });
    } catch (err) {
      console.error('Error in handleAction:', err);
      toast({
        title: "Chyba",
        description: err instanceof Error ? err.message : "Neznámá chyba",
        variant: "destructive",
      });
    }
  };

  return (
    <Card>
      <Button onClick={handleAction}>
        {requiredProp}
      </Button>
    </Card>
  );
}
```

### Props Guidelines

**DO:**
- ✅ Use TypeScript interfaces for all props
- ✅ Provide default values for optional props
- ✅ Use optional chaining for callback props (`onAction?.()`)
- ✅ Keep prop names descriptive and consistent
- ✅ Use `onX` pattern for event handlers

**DON'T:**
- ❌ Use `any` type
- ❌ Pass entire objects when only specific properties needed
- ❌ Use index as key in lists (use unique IDs)

### Performance Optimization

```typescript
import { memo, useMemo, useCallback } from "react";

// Memoize expensive computations
const expensiveValue = useMemo(() => {
  return data.map(item => ({
    ...item,
    computed: heavyCalculation(item)
  }));
}, [data]);

// Memoize callbacks to prevent re-renders
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

// Memoize components that render frequently
export const ExpensiveComponent = memo(({ data }: Props) => {
  return <div>{/* ... */}</div>;
});
```

### Accessibility Standards

**Required Practices:**
- ✅ Semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<section>`)
- ✅ ARIA labels for icon-only buttons
- ✅ Keyboard navigation support (Tab, Enter, Escape)
- ✅ Focus management in modals and dialogs
- ✅ Form labels with `htmlFor` attribute
- ✅ Color contrast ratio minimum 4.5:1

```typescript
// Good example
<Button
  aria-label="Zahájit onboarding proces"
  onClick={handleStart}
>
  <PlayCircle className="h-4 w-4" />
  Začít
</Button>

// Form accessibility
<div className="space-y-2">
  <Label htmlFor="leadSelect">Výběr leada</Label>
  <Select id="leadSelect" value={selectedId} onValueChange={setSelectedId}>
    <SelectTrigger>
      <SelectValue placeholder="Vyberte leada..." />
    </SelectTrigger>
    <SelectContent>
      {/* options */}
    </SelectContent>
  </Select>
</div>
```

---

## 🗄️ Database Integration Standards

### CRITICAL: Always Use RPC Functions

**❌ NEVER use direct database queries:**
```typescript
// WRONG - Direct query
const { data } = await supabase
  .from('leads')
  .select('*')
  .eq('organization_id', orgId);
```

**✅ ALWAYS use RPC functions:**
```typescript
// CORRECT - RPC function
const { data } = await supabase.rpc('get_open_leads_for_onboarding', {
  p_organization_id: organizationId
});
```

**Why RPC Functions?**
- ✅ Centralized business logic in database
- ✅ Better security with SECURITY DEFINER
- ✅ Easier to test and maintain
- ✅ Enforces organization-based RLS
- ✅ Better error handling and validation

### Database Naming Conventions

**Database (snake_case) → TypeScript (PascalCase):**
```typescript
// Database: onboarding_steps table
// TypeScript: OnboardingStep interface

interface OnboardingStep {
  id: string;
  onboardingId: string;        // onboarding_id in DB
  stepNumber: number;          // step_number in DB
  isCompleted: boolean;        // is_completed in DB
  completedAt: Date | null;    // completed_at in DB
  createdBy: string;           // created_by in DB
}
```

**Column Naming Patterns:**
- Boolean flags: `is_*`, `has_*` (e.g., `is_completed`, `has_waiver`)
- Timestamps: `*_at` (e.g., `created_at`, `completed_at`, `deleted_at`)
- Foreign keys: `*_id` (e.g., `organization_id`, `lead_id`)
- Function parameters: `p_*` (e.g., `p_onboarding_id`, `p_organization_id`)
- Variables in functions: `v_*` (e.g., `v_onboarding`, `v_organization_id`)

### Custom Hooks for Data Fetching

```typescript
// Standard hook pattern with React Query
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export function useOnboarding(onboardingId: string | null) {
  const queryClient = useQueryClient();

  // Fetch data
  const { data: onboarding, isLoading, error } = useQuery({
    queryKey: ['onboarding', onboardingId],
    queryFn: async () => {
      if (!onboardingId) return null;

      const { data, error } = await supabase.rpc('get_onboarding_with_steps', {
        p_onboarding_id: onboardingId
      });

      if (error) throw error;
      return data;
    },
    enabled: !!onboardingId,
  });

  // Mutation
  const completeStepMutation = useMutation({
    mutationFn: async (stepNumber: number) => {
      const { data, error } = await supabase.rpc('complete_onboarding_step', {
        p_onboarding_id: onboardingId,
        p_step_number: stepNumber
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['onboarding', onboardingId] });
    },
  });

  return {
    onboarding,
    isLoading,
    error,
    completeStep: completeStepMutation.mutate,
    isCompletingStep: completeStepMutation.isPending,
  };
}
```

### Error Handling

```typescript
// Component-level error handling
try {
  const { data, error } = await supabase.rpc('create_onboarding', {
    p_lead_id: leadId,
    p_consultation_date: date,
    p_consultation_time: time
  });

  if (error) throw error;
  if (!data) throw new Error('No data returned');

  toast({
    title: "Úspěch",
    description: "Onboarding byl vytvořen",
  });

  navigate(`/clients/onboarding/step1?onboardingId=${data.id}`);
} catch (err) {
  console.error('Error creating onboarding:', err);
  toast({
    title: "Chyba",
    description: err instanceof Error ? err.message : "Nepodařilo se vytvořit onboarding",
    variant: "destructive",
  });
}
```

### Database Migration Standards

**See:** `docs/database-current/MIGRATION-GUIDE.md` for comprehensive migration guide.

**Critical Migration Patterns:**

1. **Always start update/fix migrations with DROP:**
```sql
-- For updates to existing functions, ALWAYS start with:
DROP FUNCTION IF EXISTS function_name(param_types);

-- Then recreate
CREATE OR REPLACE FUNCTION function_name(...) ...;
```

2. **Use sequential numbering:**
```
001-add-get-open-leads-function.sql
002-fix-create-onboarding-function.sql
003-add-trainer-assignment.sql
```

3. **Include comprehensive documentation:**
```sql
-- =====================================================================
-- Migration: 001 - Add Feature Name
-- =====================================================================
-- Created: YYYY-MM-DD
-- Purpose: Brief description of what this migration does
-- Reason: Why this migration is needed
-- =====================================================================
```

4. **Always include rollback instructions:**
```sql
-- =====================================================================
-- Rollback Instructions
-- =====================================================================
-- To rollback this migration, run:
-- DROP FUNCTION IF EXISTS function_name(param_types);
```

---

## 🔐 Security Requirements

### Frontend-First Security Model

**⚠️ CRITICAL: When using Supabase directly from the frontend, your security model is fundamentally different from traditional backend architectures.**

**Key Security Layers:**
1. **Database RLS** - Your primary security layer (see DATABASE-STANDARDS.md)
2. **API Key Management** - Protecting access credentials
3. **Client-Side Validation** - User experience (NOT security)
4. **Authentication** - Session and user management

### API Key Management

**Key Management Rules:**
1. ✅ Anon key goes in frontend environment variables (e.g., `VITE_SUPABASE_ANON_KEY`)
2. ❌ Service role key NEVER goes in any frontend-accessible location
3. ✅ Service role key should only exist in server-side code, CI/CD secrets, or local admin scripts

### Authentication & Session Management

**Implementation:**
- Session timeout: 30 minutes of inactivity
- Automatic logout on timeout
- Secure cookies: `SameSite=Strict`, `HttpOnly=true`
- HTTPS only in production

```typescript
// Check authentication status
const { user, organizationId } = useAuth();

if (!user) {
  return <Navigate to="/login" />;
}
```

### Row Level Security (RLS)

**Critical Principle:** Organization-based data isolation

**Frontend Developer Responsibilities:**
- Understand that RLS is your primary security layer
- Never attempt to bypass RLS or use service role key in frontend
- Report any data access issues that might indicate RLS misconfiguration

**For RLS Implementation Details:** See `DATABASE-STANDARDS.md` Section 6

**Quick Reference:**
```sql
-- All tables must have RLS enabled
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboardings ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Policies enforce organization-based isolation
-- See DATABASE-STANDARDS.md for full policy examples
```

### Input Validation: Client-Side vs Server-Side

**⚠️ CRITICAL: Client-side validation is for user experience ONLY, not security.**

**Two-Layer Validation Strategy:**

1. **Client-Side (Zod)** - Immediate user feedback, better UX
2. **Database-Side (SQL)** - Actual security enforcement, cannot be bypassed

**Client-Side Validation with Zod:**

```typescript
import { z } from "zod";

// Define schema for UX validation
const OnboardingSchema = z.object({
  leadId: z.string().uuid("Invalid lead ID"),
  consultationDate: z.string().date().optional(),
  consultationTime: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).optional(),
});

const LeadSchema = z.object({
  firstName: z.string().min(2, "Jméno musí mít alespoň 2 znaky").max(100),
  lastName: z.string().min(2, "Příjmení musí mít alespoň 2 znaky").max(100),
  email: z.string().email("Neplatný email"),
  phone: z.string().regex(/^\+?[0-9]{9,15}$/, "Neplatné telefonní číslo").optional(),
});

// Validate in component for UX
try {
  const validated = OnboardingSchema.parse({
    leadId,
    consultationDate,
    consultationTime
  });
  // Use validated data
} catch (err) {
  if (err instanceof z.ZodError) {
    toast({
      title: "Chyba validace",
      description: err.errors[0].message,
      variant: "destructive",
    });
  }
}
```

### XSS & CSRF Protection

**Best Practices:**
- ✅ Use React's `{variable}` syntax (auto-escapes)
- ❌ NEVER use `dangerouslySetInnerHTML` unless absolutely necessary
- ✅ Sanitize user input with DOMPurify if HTML rendering required
- ✅ Use CSRF tokens for all mutations
- ✅ Set Content Security Policy headers

```typescript
// Safe rendering
<p>{userProvidedText}</p>  // ✅ Auto-escaped

// If HTML is absolutely necessary
import DOMPurify from 'dompurify';

const sanitized = DOMPurify.sanitize(userProvidedHtml);
<div dangerouslySetInnerHTML={{ __html: sanitized }} />  // ⚠️ Use with caution
```

### Rate Limiting

**Configure rate limits for sensitive operations:**

```typescript
// Conceptual - implement at API/database level
const rateLimits = {
  onboardingCreation: { windowMs: 60000, max: 5 },      // 5 per minute
  authentication: { windowMs: 900000, max: 5 },         // 5 per 15 minutes
  dataExport: { windowMs: 3600000, max: 2 },           // 2 per hour
};
```

**Database-level rate limiting:**
```sql
-- Track and limit operations in RPC functions
CREATE TABLE IF NOT EXISTS rate_limit_tracking (
  user_id UUID NOT NULL,
  operation VARCHAR(50) NOT NULL,
  last_attempt TIMESTAMP NOT NULL DEFAULT NOW(),
  attempt_count INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (user_id, operation)
);
```

### Data Privacy & GDPR Compliance

**Data Minimization:**
- Only collect data necessary for business operations
- Lead data: first_name, last_name, email, phone, current_status
- Client data: Add health questionnaire, membership info
- NO unnecessary personal data

**Audit Logging:**
```sql
-- Log critical operations
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  action VARCHAR(50) NOT NULL,  -- 'CREATE', 'UPDATE', 'DELETE'
  resource VARCHAR(50) NOT NULL, -- 'lead', 'onboarding', 'client'
  resource_id UUID NOT NULL,
  ip_address INET,
  details JSONB
);

-- Log in RPC functions
INSERT INTO audit_logs (user_id, action, resource, resource_id, details)
VALUES (
  auth.uid(),
  'CREATE',
  'onboarding',
  v_onboarding.id,
  jsonb_build_object('lead_id', p_lead_id)
);
```

### Security Checklist for New Features

Before deploying any new feature, verify:

**Frontend Security:**
- [ ] Using anon key (NEVER service role key) in frontend code
- [ ] Client-side validation with Zod schemas for UX
- [ ] Error messages don't reveal sensitive information
- [ ] No sensitive data in console.log statements
- [ ] Environment variables properly configured (.env files)
- [ ] TypeScript strict mode passes
- [ ] Accessibility standards met

**Database Security (see DATABASE-STANDARDS.md):**
- [ ] RLS policies active on all new tables
- [ ] Database functions validate ALL inputs
- [ ] Using RPC functions (no direct queries)
- [ ] Audit logging for critical operations
- [ ] Rate limiting for mutations
- [ ] Functions use `auth.uid()` for user identification (never client-provided IDs)

---

## 🧪 Testing Requirements

### Component Testing

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Start } from './Start';

describe('Start Onboarding', () => {
  it('should load and display leads', async () => {
    const queryClient = new QueryClient();

    render(
      <QueryClientProvider client={queryClient}>
        <Start />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText(/Výběr leada/i)).toBeInTheDocument();
    });
  });

  it('should validate consultation date', async () => {
    // Test implementation
  });
});
```

### Database Function Testing

```sql
-- Test in Supabase SQL Editor
DO $$
DECLARE
  v_test_org_id UUID;
  v_test_lead_id UUID;
  v_result RECORD;
BEGIN
  -- Setup test data
  INSERT INTO leads (id, organization_id, first_name, last_name, email)
  VALUES (gen_random_uuid(), gen_random_uuid(), 'Test', 'User', 'test@example.com')
  RETURNING id, organization_id INTO v_test_lead_id, v_test_org_id;

  -- Test function
  SELECT * INTO v_result FROM get_open_leads_for_onboarding(v_test_org_id);

  -- Assertions
  ASSERT v_result.id = v_test_lead_id, 'Lead should be returned';

  -- Cleanup
  DELETE FROM leads WHERE id = v_test_lead_id;

  RAISE NOTICE 'Test passed!';
END $$;
```

### Manual Testing Checklist

Before marking a feature complete:
- [ ] Test happy path with valid data
- [ ] Test validation with invalid data
- [ ] Test error handling (network errors, database errors)
- [ ] Test edge cases (empty states, null values)
- [ ] Test on different screen sizes (mobile, tablet, desktop)
- [ ] Test keyboard navigation
- [ ] Test with screen reader
- [ ] Verify browser console has no errors
- [ ] Verify no network request failures

---

## 🚀 Development Workflow

### Starting Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# In separate terminal, start Supabase (if local)
supabase start
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/onboarding-step-improvements

# Make changes and commit
git add .
git commit -m "feat: Add validation to onboarding step 1"

# Push to remote
git push origin feature/onboarding-step-improvements

# Create pull request on GitHub
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(onboarding): Add progress tracking to all steps

Added completedSteps calculation and display to show
users which steps they've completed in the onboarding flow.

Closes #123
```

```
fix(database): Remove deleted_at check from leads queries

Leads table doesn't have deleted_at column, causing
queries to fail. Updated RPC functions accordingly.

Closes #124
```

### Code Review Guidelines

**Reviewer Checklist:**
- [ ] Code follows naming conventions
- [ ] No direct database queries (only RPC functions)
- [ ] Proper error handling and user feedback
- [ ] TypeScript types are correct and specific
- [ ] Accessibility standards met
- [ ] Input validation implemented
- [ ] No security vulnerabilities
- [ ] Tests pass (if applicable)
- [ ] Documentation updated (if needed)

---

## 📚 Reference Documentation

### Internal Documentation
- **Database Standards:** `docs/database-current/DATABASE-STANDARDS.md`
- **Migration Guide:** `docs/database-current/MIGRATION-GUIDE.md`
- **Database Schema:** `docs/database-current/database-schema-documentation.md`
- **Migration Planning:** `docs/migration/`

### External Resources
- [React Documentation](https://react.dev/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [shadcn/ui Components](https://ui.shadcn.com/)
- [React Query Documentation](https://tanstack.com/query/latest)

---

## 🎯 Project-Specific Patterns

### Onboarding Flow Architecture

```
Start Page (Step 0)
  ↓
Select Lead → Create Onboarding Record
  ↓
Step 1: Časy a frekvence cvičení
Step 2: Datum diagnostiky
Step 3: Datum prvního tréninku
Step 4: Platba a členství
Step 5: Zdravotní dotazník
Step 6: Předání pomůcek
Step 7: SMS potvrzení
Step 8: Ukončení konzultace
Step 9: Administrace
  ↓
Complete → Create Client Record
```

### Lead Status Flow

```sql
-- Lead statuses (from lead_status table)
new → contacted → consultation_scheduled →
consultation_completed → closed_won / closed_lost

-- Only open leads (not closed_won/closed_lost) can start onboarding
```

### Organization-Based Access

All data access must filter by organization membership:

```typescript
// Get current user's organization
const { organizationId } = useAuth();

// Pass to RPC functions
const { data } = await supabase.rpc('get_function_name', {
  p_organization_id: organizationId
});
```

### Common UI Patterns

**Loading States:**
```typescript
if (isLoading) {
  return (
    <div className="text-center py-12">
      <p className="text-muted-foreground">Načítání...</p>
    </div>
  );
}
```

**Empty States:**
```typescript
if (!data || data.length === 0) {
  return (
    <div className="text-center py-8">
      <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
      <p className="text-muted-foreground mb-4">
        Žádná data nebyla nalezena
      </p>
      <Button onClick={handleCreate}>
        Vytvořit nový záznam
      </Button>
    </div>
  );
}
```

**Error States:**
```typescript
if (error) {
  return (
    <div className="text-center py-8">
      <AlertCircle className="h-12 w-12 text-destructive mx-auto mb-4" />
      <p className="text-destructive mb-4">
        {error instanceof Error ? error.message : "Nastala chyba"}
      </p>
      <Button onClick={refetch}>
        Zkusit znovu
      </Button>
    </div>
  );
}
```

---

## 🔄 Continuous Improvement

This guide is a living document. When you discover new patterns, best practices, or encounter issues:

1. **Document the pattern** in the appropriate section
2. **Update examples** to reflect current best practices
3. **Remove outdated information** that no longer applies
4. **Keep it concise** - focus on what developers need to know

**Last Updated:** 2025-11-24
**Version:** 1.0.0
