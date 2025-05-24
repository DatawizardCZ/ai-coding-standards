# Mobile-Responsive UI Patterns

## 🎯 Mobile-First Component Architecture

### Core Responsive Principles
- **Mobile-first design**: Start with mobile constraints, enhance for larger screens
- **Touch-friendly interactions**: Minimum 44px × 44px touch targets
- **Performance-first**: Optimize for slower mobile connections
- **Gesture support**: Swipe, pinch, long-press patterns

### Breakpoint Strategy
```typescript
// Tailwind breakpoints used in project
const breakpoints = {
  sm: '640px',   // Small tablets
  md: '768px',   // Tablets
  lg: '1024px',  // Small desktops
  xl: '1280px'   // Large desktops
}

// Usage pattern: mobile-first
className="w-full md:w-auto px-4 py-3 md:px-6 md:py-2"
```

## 📱 Component Responsive Patterns

### Modal Components
```typescript
// Mobile: Full-screen overlay
// Desktop: Centered modal with max-width
interface ResponsiveModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  size?: 'sm' | 'md' | 'lg' | 'full'
}

const ResponsiveModal = ({ isOpen, onClose, title, size = 'md' }) => {
  const sizeClasses = {
    sm: 'w-full md:w-[400px] h-full md:h-auto',
    md: 'w-full md:w-[600px] h-full md:h-auto md:max-h-[90vh]',
    lg: 'w-full md:w-[800px] h-full md:h-auto md:max-h-[90vh]',
    full: 'w-full h-full'
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-end md:items-center justify-center z-50">
      <div className={`bg-white rounded-t-2xl md:rounded-xl ${sizeClasses[size]} overflow-hidden`}>
        {/* Mobile: Drag indicator */}
        <div className="md:hidden w-12 h-1 bg-gray-300 rounded-full mx-auto mt-3" />
        
        {/* Header with mobile-optimized spacing */}
        <div className="px-4 md:px-6 py-4 md:py-4 border-b border-gray-200 flex justify-between items-center">
          <h2 className="text-lg md:text-xl font-semibold">{title}</h2>
          <button 
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-full touch-target"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        
        {/* Scrollable content */}
        <div className="overflow-y-auto flex-1 p-4 md:p-6">
          {children}
        </div>
      </div>
    </div>
  )
}
```

### Form Input Patterns
```typescript
// Mobile-optimized form inputs
const MobileFormField = ({ label, error, required, children }) => (
  <div className="space-y-2">
    <label className="block text-sm font-medium text-gray-700">
      {label}
      {required && <span className="text-red-500 ml-1">*</span>}
    </label>
    <div className="relative">
      {/* Mobile: Larger padding, bigger text */}
      <input 
        className="w-full px-4 py-4 md:px-3 md:py-2 text-base md:text-sm border border-gray-300 rounded-lg md:rounded-md focus:ring-2 focus:ring-primary-400 focus:border-transparent"
        {...inputProps}
      />
    </div>
    {error && (
      <p className="text-sm text-red-600 flex items-center">
        <AlertCircle className="w-4 h-4 mr-1" />
        {error}
      </p>
    )}
  </div>
)
```

### Button Patterns
```typescript
// Touch-friendly button sizing
const ResponsiveButton = ({ variant, size, children, ...props }) => {
  const baseClasses = "font-medium rounded-lg transition-colors touch-target"
  
  const sizeClasses = {
    sm: "px-3 py-2 md:px-2 md:py-1 text-sm min-h-[44px] md:min-h-[32px]",
    md: "px-4 py-3 md:px-4 md:py-2 text-base md:text-sm min-h-[48px] md:min-h-[36px]",
    lg: "px-6 py-4 md:px-6 md:py-3 text-lg md:text-base min-h-[52px] md:min-h-[40px]"
  }
  
  const variantClasses = {
    primary: "bg-[#E63946] hover:bg-[#EC5766] text-white",
    secondary: "bg-white border border-gray-300 hover:bg-gray-50 text-gray-700",
    ghost: "hover:bg-gray-100 text-gray-700"
  }

  return (
    <button 
      className={`${baseClasses} ${sizeClasses[size]} ${variantClasses[variant]}`}
      {...props}
    >
      {children}
    </button>
  )
}
```

### Navigation Patterns
```typescript
// Mobile: Bottom navigation, Desktop: Sidebar
const ResponsiveNavigation = () => (
  <>
    {/* Desktop Sidebar */}
    <aside className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
      <div className="flex flex-col flex-grow bg-[#333A45] overflow-y-auto">
        {/* Desktop nav items */}
      </div>
    </aside>

    {/* Mobile Bottom Navigation */}
    <nav className="md:hidden fixed bottom-0 inset-x-0 bg-white border-t border-gray-200 z-50">
      <div className="flex justify-around py-2">
        {navItems.map((item) => (
          <button 
            key={item.id}
            className="flex flex-col items-center py-2 px-3 touch-target"
          >
            <item.icon className="w-6 h-6 mb-1" />
            <span className="text-xs">{item.label}</span>
          </button>
        ))}
      </div>
    </nav>
  </>
)
```

### Data Display Patterns
```typescript
// Responsive card grid
const ResponsiveCardGrid = ({ items }) => (
  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
    {items.map((item) => (
      <div 
        key={item.id}
        className="bg-white p-4 md:p-6 rounded-lg border border-gray-200 hover:shadow-md transition-shadow"
      >
        {/* Mobile: Larger touch targets */}
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-lg md:text-base font-semibold">{item.title}</h3>
          <button className="p-2 hover:bg-gray-100 rounded-full touch-target">
            <MoreVertical className="w-5 h-5" />
          </button>
        </div>
        
        {/* Responsive content layout */}
        <div className="space-y-3 md:space-y-2">
          <p className="text-base md:text-sm text-gray-600">{item.description}</p>
          
          {/* Mobile: Stack buttons, Desktop: Inline */}
          <div className="flex flex-col md:flex-row gap-2 md:gap-3 pt-2">
            <button className="w-full md:w-auto px-4 py-3 md:px-3 md:py-2 bg-[#E63946] text-white rounded-lg text-base md:text-sm">
              Primary Action
            </button>
            <button className="w-full md:w-auto px-4 py-3 md:px-3 md:py-2 border border-gray-300 rounded-lg text-base md:text-sm">
              Secondary
            </button>
          </div>
        </div>
      </div>
    ))}
  </div>
)
```

## 🎛️ Interactive Gesture Patterns

### Swipe Gestures
```typescript
// Swipeable cards for mobile
const SwipeableCard = ({ onSwipeLeft, onSwipeRight, children }) => {
  const [isDragging, setIsDragging] = useState(false)
  const [dragOffset, setDragOffset] = useState(0)

  return (
    <div 
      className="relative touch-pan-x"
      onTouchStart={() => setIsDragging(true)}
      onTouchEnd={() => {
        setIsDragging(false)
        if (Math.abs(dragOffset) > 100) {
          dragOffset > 0 ? onSwipeRight() : onSwipeLeft()
        }
        setDragOffset(0)
      }}
      style={{ transform: `translateX(${dragOffset}px)` }}
    >
      {children}
      
      {/* Swipe indicators */}
      {isDragging && (
        <>
          <div className="absolute inset-y-0 left-0 w-16 bg-green-500 flex items-center justify-center">
            <Check className="w-6 h-6 text-white" />
          </div>
          <div className="absolute inset-y-0 right-0 w-16 bg-red-500 flex items-center justify-center">
            <Trash className="w-6 h-6 text-white" />
          </div>
        </>
      )}
    </div>
  )
}
```

### Pull-to-Refresh
```typescript
const PullToRefreshList = ({ onRefresh, children }) => {
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [pullDistance, setPullDistance] = useState(0)

  const handleRefresh = async () => {
    setIsRefreshing(true)
    await onRefresh()
    setIsRefreshing(false)
    setPullDistance(0)
  }

  return (
    <div className="relative overflow-hidden">
      {/* Pull indicator */}
      <div 
        className="absolute top-0 inset-x-0 flex items-center justify-center py-4 transform transition-transform"
        style={{ transform: `translateY(${pullDistance - 100}px)` }}
      >
        {isRefreshing ? (
          <Loader className="w-6 h-6 animate-spin" />
        ) : (
          <ArrowDown className="w-6 h-6" />
        )}
      </div>
      
      <div 
        className="touch-pan-y"
        onTouchMove={(e) => {
          if (e.touches[0].clientY > 50) {
            setPullDistance(Math.min(e.touches[0].clientY, 100))
          }
        }}
        onTouchEnd={() => {
          if (pullDistance > 80) {
            handleRefresh()
          } else {
            setPullDistance(0)
          }
        }}
      >
        {children}
      </div>
    </div>
  )
}
```

## 🔧 Performance Optimizations

### Lazy Loading for Mobile
```typescript
// Optimize component loading
const LazyLeadModal = lazy(() => 
  import('./lead-modal').then(module => ({
    default: module.LeadModal
  }))
)

// Image optimization
const OptimizedImage = ({ src, alt, className }) => (
  <img 
    src={src}
    srcSet={`${src}?w=40 40w, ${src}?w=80 80w, ${src}?w=160 160w`}
    sizes="(max-width: 768px) 40px, (max-width: 1024px) 80px, 160px"
    className={className}
    alt={alt}
    loading="lazy"
  />
)
```

### Virtual Scrolling for Large Lists
```typescript
// For mobile performance with large datasets
const VirtualizedList = ({ items, renderItem, itemHeight = 80 }) => {
  const [visibleItems, setVisibleItems] = useState([])
  const containerRef = useRef(null)

  useEffect(() => {
    const updateVisibleItems = () => {
      if (!containerRef.current) return
      
      const { scrollTop, clientHeight } = containerRef.current
      const startIndex = Math.floor(scrollTop / itemHeight)
      const endIndex = Math.min(
        startIndex + Math.ceil(clientHeight / itemHeight) + 1,
        items.length
      )
      
      setVisibleItems(items.slice(startIndex, endIndex))
    }

    updateVisibleItems()
    containerRef.current?.addEventListener('scroll', updateVisibleItems)
    return () => containerRef.current?.removeEventListener('scroll', updateVisibleItems)
  }, [items, itemHeight])

  return (
    <div 
      ref={containerRef}
      className="h-full overflow-auto"
      style={{ height: items.length * itemHeight }}
    >
      {visibleItems.map((item, index) => renderItem(item, index))}
    </div>
  )
}
```

## 📋 Mobile Development Checklist

### Design Verification
- [ ] Touch targets minimum 44px × 44px
- [ ] Text readable at mobile sizes (minimum 16px)
- [ ] Adequate spacing between interactive elements (8px minimum)
- [ ] Color contrast meets WCAG AA standards
- [ ] Content fits in mobile viewport without horizontal scroll

### Interaction Testing
- [ ] All buttons/links work with touch
- [ ] Forms usable with mobile keyboards
- [ ] Gestures work as expected (swipe, pinch, etc.)
- [ ] Modal/overlay dismissal works on mobile
- [ ] Navigation accessible with thumb reach

### Performance Validation
- [ ] Images optimized for different screen densities
- [ ] JavaScript bundles split for mobile
- [ ] Critical CSS inlined
- [ ] Lazy loading implemented for non-critical content
- [ ] Network request optimization for slower connections

### Accessibility Compliance
- [ ] Screen reader compatible
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Alt text for images
- [ ] Semantic HTML structure

This framework ensures your components work seamlessly across all devices while maintaining performance and accessibility standards.
