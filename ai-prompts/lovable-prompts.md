# Lovable.dev Prompts & Guidelines

## 🎯 Quick Start Prompts

### Component Creation
```
Create a new [component-name] modal component following our naming conventions and modal patterns from the project knowledge. Include:
- Proper file naming (kebab-case)
- Component naming (PascalCase)
- Our modal structure and styling
- Project color system
- TypeScript interfaces with proper prop naming
```

### Hook Creation
```
Create a use[FeatureName] hook following our React Query patterns and naming conventions from project knowledge. Include:
- Proper file and hook naming
- React Query for data fetching
- Clear return object structure
- Loading and error states
- TypeScript interfaces
```

### Feature Development
```
Create a complete [feature-name] feature following our project standards:
- Component in /components/[feature]/
- Hook in /hooks/
- Follow our naming conventions
- Use our color system and modal patterns
- Include proper TypeScript types
- Reference our database schema patterns
```

## 🧩 Component-Specific Prompts

### Modal Components
```
Create a [ModalName]Modal component using our modal template:
- Follow the BaseModal structure from our templates
- Include lead info section if applicable
- Use our form patterns for user input
- Implement proper validation and error handling
- Follow our button and color styling
- Include loading states for async operations
```

### Form Components
```
Create a [FormName]Form component following our form patterns:
- Use our form hook pattern for state management
- Include proper validation with error messages
- Follow our input styling and layout
- Implement proper TypeScript interfaces
- Use our color system for validation states
- Include submit and cancel functionality
```

### Display Components
```
Create a [ComponentName] display component following our patterns:
- Use our loading state patterns
- Include empty state handling
- Follow our card/list styling
- Implement proper click handlers with "on" prefix
- Use our icon and color system
- Include hover and interaction states
```

## 🎣 Hook-Specific Prompts

### Data Management Hooks
```
Create a use[EntityName]Management hook with React Query:
- Follow our React Query patterns
- Include CRUD operations (create, read, update, delete)
- Implement proper cache invalidation
- Use our error handling patterns
- Return descriptive object with clear naming
- Include optimistic updates where appropriate
```

### Form Hooks
```
Create a use[FormName]Form hook for form state management:
- Follow our form hook template
- Include field validation with error messages
- Implement updateField and resetForm functions
- Use proper TypeScript interfaces
- Include isDirty and isValid computed values
- Handle form submission with async support
```

### Feature Hooks
```
Create a use[FeatureName] hook for [feature] functionality:
- Use React Query for any API calls
- Include proper state management
- Implement clear action functions
- Follow our loading and error state patterns
- Return organized object with logical grouping
- Include cleanup and reset functionality
```

## 🔧 Database Integration Prompts

### API Functions
```
Create API functions for [entity] following our database patterns:
- Use camelCase function names with clear verbs
- Follow our Supabase query patterns
- Include proper TypeScript types matching our schema
- Implement error handling
- Use our database naming conventions (snake_case tables, PascalCase interfaces)
- Include proper joins and relationships
```

### Database Types
```
Create TypeScript interfaces for [entity] following our database conventions:
- Use PascalCase for interface names
- Keep field names as snake_case (matching database)
- Include proper foreign key relationships
- Use our Database generated types as base
- Create derived types for common use cases (WithJoins, Insert, Update)
- Include proper optional/required field handling
```

## 🎨 Styling & UI Prompts

### Component Styling
```
Style this component following our design system:
- Use our project color palette (reference project knowledge for specific colors)
- Apply primary color for main actions and emphasis
- Use accent color for positive actions and highlights
- Apply secondary/neutral colors for backgrounds and less prominent elements
- Follow our spacing and layout patterns
- Include hover and focus states with appropriate color variations
- Use our border radius, shadow, and spacing standards
- Implement responsive design patterns
- Include proper accessibility attributes (contrast, focus indicators)
- Follow our typography scale and font weights
```

### Modal Styling
```
Apply our modal styling patterns:
- Use our modal overlay and container classes
- Include proper header with icon and title
- Add lead info section if applicable
- Style form elements with our patterns
- Use our button styles and colors
- Include proper spacing and borders
- Implement responsive behavior
```

## 🔄 Common Correction Prompts

### Naming Corrections
```
Please update this to follow our naming conventions from project knowledge:
- Files should be kebab-case: [correct-file-name]
- Components should be PascalCase: [CorrectComponentName]
- Props should use "on" prefix for event handlers
- Use "is/has/can" prefixes for boolean props
- Constants should be SCREAMING_SNAKE_CASE
```

### Structure Corrections
```
Please reorganize this to match our project structure:
- Move to correct feature folder: /components/[feature]/
- Follow our component organization patterns
- Use proper import/export conventions
- Reference our templates for structure
- Include proper TypeScript interfaces
```

### React Query Corrections
```
Please update this hook to follow our React Query patterns:
- Use useQuery for data fetching
- Use useMutation for data modifications
- Include proper cache invalidation
- Follow our error handling patterns
- Return organized object with clear naming
- Include proper loading states
```

### Database Integration Corrections
```
Please update the database integration to follow our patterns:
- Use snake_case for database table references
- TypeScript interfaces should have PascalCase names with snake_case fields
- API functions should use camelCase verbs
- Follow our Supabase query patterns
- Include proper error handling
```

## 🎪 Advanced Feature Prompts

### Complete Feature Development
```
Create a complete [feature-name] management system including:

1. Main component: [FeatureName]Dashboard
   - Follow our dashboard layout patterns
   - Include filtering and search functionality
   - Use our data table or card patterns
   - Implement proper loading states

2. Modal components:
   - Create[FeatureName]Modal
   - Edit[FeatureName]Modal
   - Delete[FeatureName]Modal
   - Follow our modal templates

3. Custom hooks:
   - use[FeatureName]Management for data operations
   - use[FeatureName]Form for form state
   - Follow our React Query patterns

4. API integration:
   - CRUD functions following our database patterns
   - Proper TypeScript types
   - Supabase integration

5. Follow all our naming conventions and project standards
```

### Integration Prompts
```
Integrate this component with our existing lead management system:
- Connect to useLeadManagement hook
- Include lead context where relevant
- Follow our prop passing patterns
- Use our event handler naming
- Include proper error handling
- Update lead status/activities as needed
```

## 📋 Quality Assurance Prompts

### Code Review
```
Review this code against our project standards:
- Check naming conventions compliance
- Verify TypeScript interfaces are properly defined
- Ensure React Query patterns are followed
- Confirm component structure matches our templates
- Validate database integration patterns
- Check error handling implementation
```

### Testing Prompts
```
Create test scenarios for this component/hook:
- Test happy path functionality
- Test error states and edge cases
- Verify prop validation
- Test loading states
- Check accessibility compliance
- Test responsive behavior
```

## 🎯 Optimization Prompts

### Performance
```
Optimize this component/hook for performance:
- Add proper useCallback and useMemo usage
- Implement efficient React Query caching
- Add proper dependency arrays
- Optimize re-renders
- Include proper cleanup
- Follow our performance patterns
```

### Accessibility
```
Improve accessibility for this component:
- Add proper ARIA labels and roles
- Implement keyboard navigation
- Include focus management
- Add screen reader support
- Use semantic HTML elements
- Follow WCAG guidelines
```

## 💡 Pro Tips for Lovable.dev

1. **Always reference project knowledge**: Include "following our [pattern] from project knowledge" in prompts
2. **Be specific about naming**: Mention exact file names and component names you want
3. **Reference templates**: Point to specific templates when creating similar components
4. **Include context**: Mention how the component fits into the larger system
5. **Specify integrations**: Be clear about which hooks or APIs to connect to
6. **Use correction prompts**: Keep handy prompts for common issues
7. **Build incrementally**: Start with basic structure, then add features
8. **Test frequently**: Use smaller prompts to verify AI understanding before complex features
