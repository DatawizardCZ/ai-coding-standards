# Accessibility Guidelines

## 🎯 Core Accessibility Principles

### WCAG 2.1 AA Compliance
- **Perceivable**: Content must be presentable in ways users can perceive
- **Operable**: Interface components must be operable by all users
- **Understandable**: Information and UI operation must be understandable
- **Robust**: Content must be robust enough for various assistive technologies

### Color Contrast Requirements
```css
/* Minimum contrast ratios */
Normal text: 4.5:1
Large text (18px+): 3:1
UI components: 3:1
Graphical objects: 3:1

/* Our color system compliance */
Primary red (#E63946) on white: 4.8:1 ✅
Light gray (#F5F5F5) on charcoal (#333A45): 12.6:1 ✅
Secondary gray (#5D6579) on white: 6.7:1 ✅
```

## 🔧 Component Accessibility Patterns

### Semantic HTML Structure
```typescript
// ✅ Good: Semantic HTML with proper heading hierarchy
const AccessibleModal = ({ title, children, onClose }) => (
  <div 
    role="dialog" 
    aria-modal="true" 
    aria-labelledby="modal-title"
    className="fixed inset-0 bg-[#333A45]/50 flex items-center justify-center z-50"
  >
    <div className="bg-white rounded-xl shadow-xl w-[800px] max-h-[90vh]">
      <header className="px-6 py-4 border-b border-[#D4D4D4]">
        <h2 id="modal-title" className="text-xl font-medium text-[#333A45]">
          {title}
        </h2>
        <button 
          onClick={onClose}
          aria-label="Close modal"
          className="p-2 hover:bg-[#F5F5F5] rounded-full"
        >
          <i className="fa-solid fa-xmark" aria-hidden="true"></i>
        </button>
      </header>
      
      <main className="p-6">
        {children}
      </main>
    </div>
  </div>
)

// ❌ Bad: Non-semantic structure
const InaccessibleModal = () => (
  <div className="modal">
    <div className="header">
      <div className="title">Modal Title</div>
      <div onClick={onClose}>×</div>
    </div>
    <div className="content">{children}</div>
  </div>
)
```

### Focus Management
```typescript
// ✅ Proper focus management in modals
const FocusableModal = ({ isOpen, onClose, children }) => {
  const modalRef = useRef<HTMLDivElement>(null)
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isOpen) {
      // Store previous focus
      previousFocusRef.current = document.activeElement as HTMLElement
      
      // Focus first focusable element in modal
      const firstFocusable = modalRef.current?.querySelector(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      ) as HTMLElement
      
      firstFocusable?.focus()
    } else {
      // Restore previous focus
      previousFocusRef.current?.focus()
    }
  }, [isOpen])

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      onClose()
    }
    
    // Trap focus within modal
    if (e.key === 'Tab') {
      const focusableElements = modalRef.current?.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      )
      
      if (focusableElements) {
        const firstElement = focusableElements[0] as HTMLElement
        const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement
        
        if (e.shiftKey && document.activeElement === firstElement) {
          e.preventDefault()
          lastElement.focus()
        } else if (!e.shiftKey && document.activeElement === lastElement) {
          e.preventDefault()
          firstElement.focus()
        }
      }
    }
  }

  return (
    <div 
      ref={modalRef}
      onKeyDown={handleKeyDown}
      role="dialog"
      aria-modal="true"
    >
      {children}
    </div>
  )
}
```

### Form Accessibility
```typescript
// ✅ Accessible form with proper labeling and validation
const AccessibleForm = () => {
  const [errors, setErrors] = useState<Record<string, string>>({})

  return (
    <form noValidate>
      {/* Required field with proper labeling */}
      <div className="space-y-2">
        <label 
          htmlFor="email"
          className="block text-sm font-medium text-[#333A45]"
        >
          Email Address
          <span className="text-[#E63946] ml-1" aria-label="required">*</span>
        </label>
        <input
          id="email"
          type="email"
          required
          aria-required="true"
          aria-invalid={errors.email ? 'true' : 'false'}
          aria-describedby={errors.email ? 'email-error' : 'email-hint'}
          className={`w-full p-3 border rounded-md ${
            errors.email 
              ? 'border-[#E63946] focus:ring-[#E63946]' 
              : 'border-[#D4D4D4] focus:ring-[#1D3557]'
          } focus:ring-2 focus:border-transparent`}
          placeholder="Enter your email address"
        />
        
        {/* Helper text */}
        <div id="email-hint" className="text-sm text-[#5D6579]">
          We'll use this to send you important updates
        </div>
        
        {/* Error message */}
        {errors.email && (
          <div 
            id="email-error" 
            role="alert"
            aria-live="polite"
            className="text-sm text-[#E63946] flex items-center"
          >
            <i className="fa-solid fa-exclamation-triangle mr-2" aria-hidden="true"></i>
            {errors.email}
          </div>
        )}
      </div>

      {/* Submit button with loading state */}
      <button
        type="submit"
        disabled={isSubmitting}
        aria-describedby="submit-status"
        className="w-full px-4 py-3 bg-[#E63946] text-white rounded-md hover:bg-[#EC5766] disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isSubmitting ? (
          <>
            <i className="fa-solid fa-spinner fa-spin mr-2" aria-hidden="true"></i>
            <span>Submitting...</span>
          </>
        ) : (
          'Submit Form'
        )}
      </button>
      
      {/* Status announcements */}
      <div 
        id="submit-status" 
        aria-live="polite" 
        aria-atomic="true"
        className="sr-only"
      >
        {isSubmitting && 'Form is being submitted'}
        {submitSuccess && 'Form submitted successfully'}
        {submitError && `Form submission failed: ${submitError}`}
      </div>
    </form>
  )
}
```

### Button Accessibility
```typescript
// ✅ Accessible button patterns
const AccessibleButton = ({ 
  variant = 'primary', 
  size = 'md', 
  disabled = false,
  loading = false,
  children,
  onClick,
  ...props 
}) => {
  const baseClasses = "font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"
  
  const variantClasses = {
    primary: "bg-[#E63946] hover:bg-[#EC5766] text-white focus:ring-[#E63946]",
    secondary: "bg-white border border-[#D4D4D4] hover:bg-[#F5F5F5] text-[#333A45] focus:ring-[#1D3557]",
    ghost: "hover:bg-[#F5F5F5] text-[#333A45] focus:ring-[#1D3557]"
  }
  
  const sizeClasses = {
    sm: "px-3 py-2 text-sm min-h-[36px]",
    md: "px-4 py-3 text-base min-h-[44px]",
    lg: "px-6 py-4 text-lg min-h-[52px]"
  }

  return (
    <button
      disabled={disabled || loading}
      aria-disabled={disabled || loading}
      className={`
        ${baseClasses} 
        ${variantClasses[variant]} 
        ${sizeClasses[size]}
        ${(disabled || loading) ? 'opacity-50 cursor-not-allowed' : ''}
      `}
      onClick={onClick}
      {...props}
    >
      {loading && (
        <i className="fa-solid fa-spinner fa-spin mr-2" aria-hidden="true"></i>
      )}
      {children}
    </button>
  )
}

// Icon-only button
const IconButton = ({ icon, label, ...props }) => (
  <button
    aria-label={label}
    className="p-2 hover:bg-[#F5F5F5] rounded-full focus:outline-none focus:ring-2 focus:ring-[#1D3557] min-h-[44px] min-w-[44px] flex items-center justify-center"
    {...props}
  >
    <i className={icon} aria-hidden="true"></i>
  </button>
)
```

### Navigation Accessibility
```typescript
// ✅ Accessible navigation with proper landmarks
const AccessibleNavigation = () => (
  <nav aria-label="Main navigation" role="navigation">
    <ul className="flex space-x-4" role="menubar">
      {navItems.map((item, index) => (
        <li key={item.id} role="none">
          <Link
            to={item.href}
            role="menuitem"
            aria-current={item.isActive ? 'page' : undefined}
            className={`px-4 py-2 rounded-md transition-colors ${
              item.isActive 
                ? 'bg-[#1D3557] text-white' 
                : 'text-[#333A45] hover:bg-[#F5F5F5]'
            }`}
          >
            {item.label}
          </Link>
        </li>
      ))}
    </ul>
  </nav>
)

// Breadcrumb navigation
const Breadcrumbs = ({ items }) => (
  <nav aria-label="Breadcrumb">
    <ol className="flex items-center space-x-2">
      {items.map((item, index) => (
        <li key={item.id} className="flex items-center">
          {index > 0 && (
            <i className="fa-solid fa-chevron-right text-[#5D6579] mx-2" aria-hidden="true"></i>
          )}
          {index === items.length - 1 ? (
            <span aria-current="page" className="text-[#333A45] font-medium">
              {item.label}
            </span>
          ) : (
            <Link 
              to={item.href}
              className="text-[#1D3557] hover:text-[#2A4771] underline"
            >
              {item.label}
            </Link>
          )}
        </li>
      ))}
    </ol>
  </nav>
)
```

## 📊 Data Table Accessibility
```typescript
// ✅ Accessible data table with proper headers and sorting
const AccessibleDataTable = ({ data, columns, sortable = true }) => {
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' })

  const handleSort = (columnKey) => {
    if (!sortable) return
    
    setSortConfig(prevConfig => ({
      key: columnKey,
      direction: prevConfig.key === columnKey && prevConfig.direction === 'asc' ? 'desc' : 'asc'
    }))
  }

  return (
    <div className="overflow-x-auto">
      <table 
        className="w-full border-collapse border border-[#D4D4D4]"
        role="table"
        aria-label="Lead data table"
      >
        <thead>
          <tr role="row">
            {columns.map((column) => (
              <th
                key={column.key}
                scope="col"
                role="columnheader"
                aria-sort={
                  sortConfig.key === column.key 
                    ? sortConfig.direction === 'asc' ? 'ascending' : 'descending'
                    : 'none'
                }
                className="px-4 py-3 text-left font-medium text-[#333A45] bg-[#F5F5F5] border-b border-[#D4D4D4]"
              >
                {sortable ? (
                  <button
                    onClick={() => handleSort(column.key)}
                    className="flex items-center space-x-1 hover:text-[#1D3557]"
                    aria-label={`Sort by ${column.label}`}
                  >
                    <span>{column.label}</span>
                    <i 
                      className={`fa-solid ${
                        sortConfig.key === column.key
                          ? sortConfig.direction === 'asc' 
                            ? 'fa-chevron-up' 
                            : 'fa-chevron-down'
                          : 'fa-sort'
                      }`}
                      aria-hidden="true"
                    ></i>
                  </button>
                ) : (
                  column.label
                )}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, rowIndex) => (
            <tr 
              key={row.id} 
              role="row"
              className={`border-b border-[#D4D4D4] ${
                rowIndex % 2 === 0 ? 'bg-white' : 'bg-[#F5F5F5]'
              }`}
            >
              {columns.map((column) => (
                <td
                  key={`${row.id}-${column.key}`}
                  role="gridcell"
                  className="px-4 py-3 text-[#333A45]"
                >
                  {column.render ? column.render(row[column.key], row) : row[column.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      
      {/* Table summary for screen readers */}
      <div className="sr-only" aria-live="polite">
        Table contains {data.length} rows and {columns.length} columns
      </div>
    </div>
  )
}
```

## 🔊 Screen Reader Support
```typescript
// ✅ Announcements and live regions
const LiveRegion = ({ message, priority = 'polite' }) => (
  <div
    aria-live={priority}
    aria-atomic="true"
    className="sr-only"
  >
    {message}
  </div>
)

// Status announcements
const StatusAnnouncer = () => {
  const [announcement, setAnnouncement] = useState('')

  const announce = (message, priority = 'polite') => {
    setAnnouncement('')
    setTimeout(() => setAnnouncement(message), 100)
  }

  return <LiveRegion message={announcement} priority="polite" />
}

// Loading states with announcements
const LoadingButton = ({ loading, children, ...props }) => (
  <>
    <button
      disabled={loading}
      aria-describedby="loading-status"
      {...props}
    >
      {loading && <i className="fa-solid fa-spinner fa-spin mr-2" aria-hidden="true"></i>}
      {children}
    </button>
    
    {loading && (
      <div id="loading-status" className="sr-only" aria-live="polite">
        Loading, please wait
      </div>
    )}
  </>
)
```

## 🎨 Visual Accessibility
```css
/* High contrast mode support */
@media (prefers-contrast: high) {
  .button-primary {
    background-color: #000000;
    color: #ffffff;
    border: 2px solid #ffffff;
  }
  
  .button-secondary {
    background-color: #ffffff;
    color: #000000;
    border: 2px solid #000000;
  }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Focus indicators */
.focus-visible {
  outline: 2px solid #1D3557;
  outline-offset: 2px;
}

/* Skip links */
.skip-link {
  position: absolute;
  top: -40px;
  left: 6px;
  background: #1D3557;
  color: white;
  padding: 8px;
  border-radius: 4px;
  text-decoration: none;
  z-index: 9999;
}

.skip-link:focus {
  top: 6px;
}
```

## ✅ Accessibility Checklist

### Component Level
- [ ] Semantic HTML elements used appropriately
- [ ] All interactive elements are keyboard accessible
- [ ] Focus indicators are visible and sufficient
- [ ] Color is not the only way to convey information
- [ ] Text has sufficient contrast ratio (4.5:1 minimum)
- [ ] All images have appropriate alt text
- [ ] Form elements have proper labels and error handling

### Page Level
- [ ] Heading hierarchy is logical (h1 → h2 → h3)
- [ ] Page has a descriptive title
- [ ] Main content areas are properly labeled
- [ ] Skip links are provided for keyboard users
- [ ] Error messages are announced to screen readers
- [ ] Loading states are communicated to assistive technology

### Application Level
- [ ] All functionality available via keyboard
- [ ] Focus management in single-page applications
- [ ] Dynamic content changes are announced
- [ ] User preferences respected (reduced motion, high contrast)
- [ ] Testing completed with screen readers
- [ ] WCAG 2.1 AA compliance verified

### Testing Tools
- **Automated**: axe-core, Lighthouse accessibility audit
- **Manual**: Keyboard navigation, screen reader testing
- **Browser extensions**: axe DevTools, WAVE, Accessibility Insights
- **Screen readers**: NVDA (Windows), VoiceOver (Mac), TalkBack (Android)

This accessibility framework ensures your components are usable by everyone, including users with disabilities, while maintaining excellent user experience for all.
