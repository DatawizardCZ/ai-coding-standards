# General AI Prompts for Any Project

## 🎯 Universal Component Creation Prompts

### Standard Component
```
Create a new [ComponentName] component following our project naming conventions and patterns:
- Use proper file naming convention from project standards
- Follow component naming patterns
- Include appropriate TypeScript interfaces
- Apply our design system and styling patterns
- Use our standard component structure
- Include proper prop naming with consistent prefixes
```

### Modal Component
```
Create a [ModalName]Modal component following our modal patterns:
- Use our established modal structure and layout
- Include proper header, body, and footer sections
- Apply our modal styling and overlay patterns
- Implement form validation if applicable
- Include loading states for async operations
- Follow our button styling and interaction patterns
- Use proper TypeScript interfaces for props
```

### Form Component
```
Create a [FormName]Form component with our form patterns:
- Use our form state management approach
- Include field validation with error display
- Follow our input styling and layout standards
- Implement proper TypeScript interfaces
- Use our validation state styling
- Include form submission and reset functionality
- Apply our accessibility standards
```

## 🎣 Universal Hook Creation Prompts

### Data Management Hook
```
Create a use[EntityName] hook for data management:
- Follow our data fetching patterns (React Query, SWR, or project standard)
- Include CRUD operations as needed
- Implement proper error handling
- Use our loading state patterns
- Return descriptive object with clear property names
- Include proper TypeScript interfaces
- Follow our caching and invalidation strategies
```

### Form State Hook
```
Create a use[FormName]Form hook for form state management:
- Follow our form hook patterns
- Include field validation with error messages
- Implement field update and form reset functions
- Use proper TypeScript interfaces for form data
- Include computed values (isValid, isDirty, etc.)
- Handle form submission with async support
- Apply our validation patterns
```

### Feature Hook
```
Create a use[FeatureName] hook for [feature] functionality:
- Use our data fetching approach for any API calls
- Include proper state management
- Implement clear action functions with descriptive names
- Follow our loading and error state patterns
- Return organized object with logical grouping
- Include cleanup and reset functionality
- Use appropriate TypeScript interfaces
```

## 🎨 Universal Styling & UI Prompts

### Component Styling
```
Style this component following our design system:
- Apply our project color palette (reference design system documentation)
- Use primary colors for main actions and key elements
- Apply accent colors for positive actions and highlights
- Use neutral/secondary colors for backgrounds and supporting elements
- Follow our spacing scale and layout patterns
- Include appropriate hover and focus states
- Apply our border radius, shadow, and elevation standards
- Implement responsive design according to our breakpoints
- Include proper accessibility attributes (contrast, focus management)
- Follow our typography scale and hierarchy
```

### Interactive Elements
```
Style interactive elements following our interaction patterns:
- Apply our button hierarchy and sizing
- Use our link styling and hover effects
- Implement our focus indicators and accessibility patterns
- Include loading states with our spinner/skeleton patterns
- Apply our disabled state styling
- Use our selection and active state indicators
- Follow our form control styling standards
```

### Layout & Structure
```
Apply our layout patterns to this component:
- Use our grid system and spacing standards
- Follow our container and wrapper patterns
- Apply our card and section styling
- Use our header and navigation patterns
- Implement our sidebar and panel layouts
- Follow our responsive design breakpoints
- Apply our z-index and layering standards
```

## 🔧 Universal Database Integration Prompts

### API Functions
```
Create API functions for [entity] following our backend patterns:
- Use our function naming conventions with clear verbs
- Follow our API query/mutation patterns
- Include proper TypeScript types matching our schema
- Implement our error handling approach
- Use our database naming conventions
- Include proper relationships and joins
- Apply our authentication and authorization patterns
```

### Type Definitions
```
Create TypeScript interfaces for [entity] following our type patterns:
- Use our interface naming conventions
- Match field names to our database schema
- Include proper optional/required field handling
- Define relationships and foreign keys appropriately
- Create derived types for common use cases
- Use our base types and extend appropriately
- Include proper validation schemas if applicable
```

## 🔄 Universal Correction Prompts

### Naming Convention Fixes
```
Please update this to follow our project naming conventions:
- Apply our file naming standards
- Use our component naming patterns
- Follow our variable and function naming rules
- Use our prop naming conventions (event handlers, boolean props)
- Apply our constant and enum naming standards
- Follow our TypeScript interface naming patterns
```

### Code Structure Fixes
```
Please reorganize this to match our project structure:
- Move to appropriate folder following our organization patterns
- Use our import/export conventions
- Follow our component composition patterns
- Apply our file organization standards
- Reference our established patterns and templates
```

### Pattern Compliance Fixes
```
Please update this to follow our established patterns:
- Use our data fetching approach
- Apply our state management patterns
- Follow our error handling standards
- Use our loading state patterns
- Apply our validation approaches
- Follow our accessibility guidelines
```

## 🎪 Universal Feature Development Prompts

### Complete Feature Creation
```
Create a complete [feature-name] feature following our project standards:

1. Main component: [FeatureName]Dashboard/Manager
   - Follow our dashboard/main view patterns
   - Include our standard filtering and search functionality
   - Use our data display patterns (table, cards, list)
   - Implement our loading and empty state patterns

2. Supporting components as needed:
   - Modal components following our modal patterns
   - Form components using our form standards
   - Display components with our styling patterns

3. Custom hooks:
   - Data management hook following our data patterns
   - Form state hooks using our form patterns
   - Feature-specific hooks as needed

4. Integration:
   - API functions following our backend patterns
   - Proper TypeScript types matching our standards
   - Database integration using our approach

5. Apply all our naming conventions and project standards
```

### Integration with Existing System
```
Integrate this component with our existing [system] following our patterns:
- Connect to appropriate data management hooks
- Include relevant context where needed
- Follow our prop passing and event handling patterns
- Use our error handling and loading state approaches
- Update related state/data as needed per our patterns
- Maintain consistency with existing component interfaces
```

## 📋 Universal Quality Assurance Prompts

### Code Review
```
Review this code against our project standards:
- Verify naming convention compliance
- Check TypeScript interface definitions
- Confirm our established patterns are followed
- Validate component structure matches our standards
- Check integration patterns are correct
- Verify error handling implementation
- Ensure accessibility standards are met
```

### Performance Optimization
```
Optimize this component/hook for performance following our standards:
- Apply our memoization patterns (useCallback, useMemo)
- Implement our efficient data fetching and caching
- Add proper dependency arrays
- Optimize re-renders using our patterns
- Include proper cleanup following our standards
- Apply our performance best practices
```

### Accessibility Enhancement
```
Improve accessibility following our accessibility standards:
- Add proper ARIA labels and roles per our guidelines
- Implement keyboard navigation using our patterns
- Include focus management following our approach
- Add screen reader support per our standards
- Use semantic HTML elements as specified
- Follow our accessibility checklist and guidelines
```

## 💡 Universal Usage Tips

1. **Reference project documentation**: Always include "following our [pattern] from project standards/knowledge"
2. **Be specific about outcomes**: Mention exact file names and component names
3. **Point to established patterns**: Reference existing templates and examples
4. **Include system context**: Explain how components fit into the larger architecture
5. **Specify integrations**: Be clear about connections to other parts of the system
6. **Use iterative prompts**: Build complexity gradually
7. **Validate understanding**: Use smaller prompts to verify AI comprehension
8. **Maintain consistency**: Reference established conventions throughout

## 🔄 Project-Specific Adaptations

To use these prompts in any project:

1. **Update references**: Replace generic terms with your project-specific patterns
2. **Add color systems**: Include your specific color palette in styling prompts
3. **Specify tech stack**: Mention your specific technologies (React Query, Zustand, etc.)
4. **Include domain terms**: Add your business domain vocabulary
5. **Reference your docs**: Point to your specific documentation and standards
6. **Adapt naming patterns**: Adjust for your specific naming conventions
7. **Include your patterns**: Reference your established component and hook patterns
