# Performance Optimization Patterns

## 🚀 Core Performance Principles

### Performance Budget
- **First Contentful Paint (FCP)**: < 1.5s
- **Largest Contentful Paint (LCP)**: < 2.5s
- **Cumulative Layout Shift (CLS)**: < 0.1
- **First Input Delay (FID)**: < 100ms
- **JavaScript Bundle Size**: < 300KB gzipped
- **Total Page Weight**: < 1.5MB

### Loading Strategy
1. **Critical Path**: Load essential UI first
2. **Progressive Enhancement**: Add features incrementally
3. **Lazy Loading**: Defer non-critical resources
4. **Prefetching**: Anticipate user needs

## 🔧 React Performance Patterns

### Component Optimization
```typescript
// ✅ Memoization for expensive computations
const ExpensiveComponent = memo(({ data, filters }) => {
  const filteredData = useMemo(() => {
    return data.filter(item => 
      filters.every(filter => filter.predicate(item))
    )
  }, [data, filters])

  const expensiveCalculation = useMemo(() => {
    return filteredData.reduce((acc, item) => {
      // Complex calculation
      return acc + complexOperation(item)
    }, 0)
  }, [filteredData])

  return (
    <div>
      <DataDisplay data={filteredData} />
      <Summary value={expensiveCalculation} />
    </div>
  )
})

// ✅ Callback memoization
const LeadList = ({ leads, onLeadSelect, onLeadUpdate }) => {
  // Prevent unnecessary re-renders of child components
  const handleLeadSelect = useCallback((leadId: string) => {
    onLeadSelect(leadId)
  }, [onLeadSelect])

  const handleLeadUpdate = useCallback((leadId: string, data: LeadUpdate) => {
    onLeadUpdate(leadId, data)
  }, [onLeadUpdate])

  return (
    <div className="space-y-4">
      {leads.map(lead => (
        <LeadCard
          key={lead.id}
          lead={lead}
          onSelect={handleLeadSelect}
          onUpdate={handleLeadUpdate}
        />
      ))}
    </div>
  )
}
```

### Lazy Loading Components
```typescript
// ✅ Component-level lazy loading
const LazyLeadModal = lazy(() => 
  import('./lead-modal').then(module => ({
    default: module.LeadModal
  }))
)

const LazyCallScriptModal = lazy(() => import('./call-script-modal'))

// Usage with loading fallback
const LeadDashboard = () => (
  <Suspense fallback={<ModalSkeleton />}>
    {showLeadModal && <LazyLeadModal {...modalProps} />}
    {showCallModal && <LazyCallScriptModal {...callProps} />}
  </Suspense>
)

// ✅ Route-based code splitting
const LazyDashboard = lazy(() => import('../pages/dashboard'))
const LazyLeadManagement = lazy(() => import('../pages/lead-management'))
const LazySettings = lazy(() => import('../pages/settings'))

const AppRouter = () => (
  <Router>
    <Suspense fallback={<PageSkeleton />}>
      <Routes>
        <Route path="/dashboard" element={<LazyDashboard />} />
        <Route path="/leads" element={<LazyLeadManagement />} />
        <Route path="/settings" element={<LazySettings />} />
      </Routes>
    </Suspense>
  </Router>
)
```

### Virtual Scrolling for Large Lists
```typescript
// ✅ Virtual scrolling implementation
interface VirtualScrollProps<T> {
  items: T[]
  itemHeight: number
  containerHeight: number
  renderItem: (item: T, index: number) => React.ReactNode
  overscan?: number
}

const VirtualScroll = <T,>({
  items,
  itemHeight,
  containerHeight,
  renderItem,
  overscan = 5
}: VirtualScrollProps<T>) => {
  const [scrollTop, setScrollTop] = useState(0)
  
  const visibleStart = Math.floor(scrollTop / itemHeight)
  const visibleEnd = Math.min(
    visibleStart + Math.ceil(containerHeight / itemHeight),
    items.length
  )
  
  const startIndex = Math.max(0, visibleStart - overscan)
  const endIndex = Math.min(items.length, visibleEnd + overscan)
  
  const visibleItems = items.slice(startIndex, endIndex)
  
  return (
    <div
      style={{ height: containerHeight, overflow: 'auto' }}
      onScroll={(e) => setScrollTop(e.currentTarget.scrollTop)}
    >
      <div style={{ height: items.length * itemHeight, position: 'relative' }}>
        {visibleItems.map((item, index) => (
          <div
            key={startIndex + index}
            style={{
              position: 'absolute',
              top: (startIndex + index) * itemHeight,
              height: itemHeight,
              left: 0,
              right: 0
            }}
          >
            {renderItem(item, startIndex + index)}
          </div>
        ))}
      </div>
    </div>
  )
}

// Usage for lead list
const PerformantLeadList = ({ leads }) => (
  <VirtualScroll
    items={leads}
    itemHeight={80}
    containerHeight={600}
    renderItem={(lead, index) => (
      <LeadCard key={lead.id} lead={lead} />
    )}
  />
)
```

## 📊 React Query Optimization
```typescript
// ✅ Optimized data fetching with React Query
const useOptimizedLeads = () => {
  return useQuery({
    queryKey: ['leads'],
    queryFn: getLeads,
    staleTime: 5 * 60 * 1000, // 5 minutes
    cacheTime: 30 * 60 * 1000, // 30 minutes
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    retry: 3,
    retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000)
  })
}

// ✅ Pagination for large datasets
const usePaginatedLeads = (page: number, pageSize: number = 25) => {
  return useInfiniteQuery({
    queryKey: ['leads', 'paginated', pageSize],
    queryFn: ({ pageParam = 0 }) => 
      getLeads({ offset: pageParam * pageSize, limit: pageSize }),
    getNextPageParam: (lastPage, pages) => 
      lastPage.length === pageSize ? pages.length : undefined,
    staleTime: 5 * 60 * 1000
  })
}

// ✅ Optimistic updates for better UX
const useLeadMutations = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: updateLead,
    onMutate: async ({ id, data }) => {
      // Cancel outgoing queries
      await queryClient.cancelQueries(['leads'])
      
      // Snapshot previous value
      const previousLeads = queryClient.getQueryData(['leads'])
      
      // Optimistically update
      queryClient.setQueryData(['leads'], (old: Lead[] | undefined) => 
        old?.map(lead => lead.id === id ? { ...lead, ...data } : lead)
      )
      
      return { previousLeads }
    },
    onError: (err, variables, context) => {
      // Rollback on error
      if (context?.previousLeads) {
        queryClient.setQueryData(['leads'], context.previousLeads)
      }
    },
    onSettled: () => {
      // Always refetch after error or success
      queryClient.invalidateQueries(['leads'])
    }
  })
}
```

## 🖼️ Image Optimization
```typescript
// ✅ Responsive images with lazy loading
const OptimizedImage = ({ 
  src, 
  alt, 
  className,
  sizes = "(max-width: 768px) 100vw, 50vw",
  priority = false 
}) => {
  const [isLoaded, setIsLoaded] = useState(false)
  const [isInView, setIsInView] = useState(false)
  const imgRef = useRef<HTMLImageElement>(null)

  useEffect(() => {
    if (!imgRef.current || priority) return

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsInView(true)
          observer.disconnect()
        }
      },
      { threshold: 0.1 }
    )

    observer.observe(imgRef.current)
    return () => observer.disconnect()
  }, [priority])

  const shouldLoad = priority || isInView

  return (
    <div className={`relative overflow-hidden ${className}`}>
      {/* Placeholder */}
      {!isLoaded && (
        <div className="absolute inset-0 bg-[#F5F5F5] animate-pulse" />
      )}
      
      {shouldLoad && (
        <img
          ref={imgRef}
          src={src}
          srcSet={`
            ${src}?w=400 400w,
            ${src}?w=800 800w,
            ${src}?w=1200 1200w
          `}
          sizes={sizes}
          alt={alt}
          className={`transition-opacity duration-300 ${
            isLoaded ? 'opacity-100' : 'opacity-0'
          }`}
          onLoad={() => setIsLoaded(true)}
          loading={priority ? 'eager' : 'lazy'}
        />
      )}
    </div>
  )
}

// ✅ Avatar with fallback
const UserAvatar = ({ user, size = 'md' }) => {
  const [imageError, setImageError] = useState(false)
  
  const sizeClasses = {
    sm: 'w-8 h-8 text-xs',
    md: 'w-12 h-12 text-sm',
    lg: 'w-16 h-16 text-base'
  }

  if (imageError || !user.avatarUrl) {
    return (
      <div className={`
        ${sizeClasses[size]} 
        bg-[#1D3557] text-white rounded-full 
        flex items-center justify-center font-medium
      `}>
        {user.firstName?.[0]}{user.lastName?.[0]}
      </div>
    )
  }

  return (
    <OptimizedImage
      src={user.avatarUrl}
      alt={`${user.firstName} ${user.lastName}`}
      className={`${sizeClasses[size]} rounded-full`}
      onError={() => setImageError(true)}
    />
  )
}
```

## ⚡ Bundle Optimization
```typescript
// ✅ Tree-shaking friendly imports
// Instead of: import * as icons from 'lucide-react'
import { User, Phone, Mail, Calendar } from 'lucide-react'

// Instead of: import { format, parse, isValid } from 'date-fns'
import format from 'date-fns/format'
import parse from 'date-fns/parse'
import isValid from 'date-fns/isValid'

// ✅ Dynamic imports for heavy libraries
const loadHeavyChart = () => import('recharts').then(module => module.LineChart)
const loadDatePicker = () => import('react-day-picker')

// ✅ Conditional loading based on feature flags
const ConditionalFeature = ({ featureEnabled, children }) => {
  if (!featureEnabled) return null
  
  return (
    <Suspense fallback={<div>Loading feature...</div>}>
      {children}
    </Suspense>
  )
}
```

## 🔄 State Management Optimization
```typescript
// ✅ Optimized context to prevent unnecessary re-renders
const LeadDataContext = createContext()
const LeadActionsContext = createContext()

const LeadProvider = ({ children }) => {
  const [leads, setLeads] = useState([])
  const [filters, setFilters] = useState({})
  const [selectedLeadIds, setSelectedLeadIds] = useState([])

  // Memoize actions to prevent re-renders
  const actions = useMemo(() => ({
    updateLead: (id, data) => {
      setLeads(prev => prev.map(lead => 
        lead.id === id ? { ...lead, ...data } : lead
      ))
    },
    selectLead: (id) => {
      setSelectedLeadIds(prev => 
        prev.includes(id) 
          ? prev.filter(leadId => leadId !== id)
          : [...prev, id]
      )
    },
    clearSelection: () => setSelectedLeadIds([]),
    updateFilters: (newFilters) => setFilters(prev => ({ ...prev, ...newFilters }))
  }), [])

  // Memoize data to prevent re-renders
  const data = useMemo(() => ({
    leads,
    filters,
    selectedLeadIds,
    filteredLeads: leads.filter(lead => 
      Object.entries(filters).every(([key, value]) => 
        !value || lead[key] === value
      )
    )
  }), [leads, filters, selectedLeadIds])

  return (
    <LeadDataContext.Provider value={data}>
      <LeadActionsContext.Provider value={actions}>
        {children}
      </LeadActionsContext.Provider>
    </LeadDataContext.Provider>
  )
}

// Optimized hooks for context consumption
const useLeadData = () => {
  const context = useContext(LeadDataContext)
  if (!context) throw new Error('useLeadData must be used within LeadProvider')
  return context
}

const useLeadActions = () => {
  const context = useContext(LeadActionsContext)
  if (!context) throw new Error('useLeadActions must be used within LeadProvider')
  return context
}
```

## 🎯 Performance Monitoring
```typescript
// ✅ Performance measurement hooks
const usePerformanceMonitor = (componentName: string) => {
  const mountTime = useRef(performance.now())
  const renderCount = useRef(0)

  useEffect(() => {
    renderCount.current += 1
  })

  useEffect(() => {
    const mountDuration = performance.now() - mountTime.current
    
    // Log slow mounts
    if (mountDuration > 100) {
      console.warn(`Slow mount: ${componentName} took ${mountDuration.toFixed(2)}ms`)
    }

    return () => {
      const totalTime = performance.now() - mountTime.current
      console.log(`${componentName}: ${renderCount.current} renders in ${totalTime.toFixed(2)}ms`)
    }
  }, [componentName])
}

// ✅ Memory leak detection
const useMemoryLeakDetection = () => {
  useEffect(() => {
    const checkMemory = () => {
      if ('memory' in performance) {
        const memory = (performance as any).memory
        const used = memory.usedJSHeapSize / 1048576 // Convert to MB
        const total = memory.totalJSHeapSize / 1048576
        
        if (used > 50) { // Alert if using more than 50MB
          console.warn(`High memory usage: ${used.toFixed(2)}MB / ${total.toFixed(2)}MB`)
        }
      }
    }

    const interval = setInterval(checkMemory, 10000) // Check every 10s
    return () => clearInterval(interval)
  }, [])
}

// ✅ Long task detection
const useLongTaskDetection = () => {
  useEffect(() => {
    if ('PerformanceObserver' in window) {
      const observer = new PerformanceObserver((list) => {
        list.getEntries().forEach((entry) => {
          if (entry.duration > 50) { // Tasks longer than 50ms
            console.warn(`Long task detected: ${entry.duration.toFixed(2)}ms`)
          }
        })
      })
      
      observer.observe({ entryTypes: ['longtask'] })
      return () => observer.disconnect()
    }
  }, [])
}
```

## 🚦 Loading States & Skeletons
```typescript
// ✅ Skeleton components for better perceived performance
const LeadCardSkeleton = () => (
  <div className="bg-white p-4 rounded-lg border border-[#D4D4D4] animate-pulse">
    <div className="flex items-center space-x-3">
      <div className="w-12 h-12 bg-[#F5F5F5] rounded-full"></div>
      <div className="flex-1 space-y-2">
        <div className="h-4 bg-[#F5F5F5] rounded w-3/4"></div>
        <div className="h-3 bg-[#F5F5F5] rounded w-1/2"></div>
      </div>
    </div>
    <div className="mt-4 space-y-2">
      <div className="h-3 bg-[#F5F5F5] rounded"></div>
      <div className="h-3 bg-[#F5F5F5] rounded w-5/6"></div>
    </div>
  </div>
)

const LeadListSkeleton = ({ count = 5 }) => (
  <div className="space-y-4">
    {Array.from({ length: count }).map((_, index) => (
      <LeadCardSkeleton key={index} />
    ))}
  </div>
)

// ✅ Progressive loading with skeleton
const LeadList = () => {
  const { data: leads, isLoading, error } = useLeadsQuery()

  if (error) {
    return <ErrorState error={error} />
  }

  if (isLoading) {
    return <LeadListSkeleton />
  }

  return (
    <div className="space-y-4">
      {leads.map(lead => (
        <LeadCard key={lead.id} lead={lead} />
      ))}
    </div>
  )
}
```

## 📱 Mobile Performance Optimizations
```typescript
// ✅ Touch response optimization
const useTouchOptimization = () => {
  useEffect(() => {
    // Disable passive event listeners for better touch response
    const options = { passive: false }
    
    const preventDefault = (e: TouchEvent) => {
      if (e.touches.length > 1) {
        e.preventDefault() // Prevent pinch zoom
      }
    }

    document.addEventListener('touchstart', preventDefault, options)
    document.addEventListener('touchmove', preventDefault, options)

    return () => {
      document.removeEventListener('touchstart', preventDefault)
      document.removeEventListener('touchmove', preventDefault)
    }
  }, [])
}

// ✅ Intersection Observer for mobile scrolling
const useLazyLoading = (ref: RefObject<HTMLElement>) => {
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    const element = ref.current
    if (!element) return

    const observer = new IntersectionObserver(
      ([entry]) => setIsVisible(entry.isIntersecting),
      {
        threshold: 0.1,
        rootMargin: '50px' // Start loading 50px before element is visible
      }
    )

    observer.observe(element)
    return () => observer.disconnect()
  }, [ref])

  return isVisible
}

// ✅ Debounced search for better performance
const useDebounce = <T>(value: T, delay: number): T => {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}

// Usage in search component
const SearchableLeadList = () => {
  const [searchTerm, setSearchTerm] = useState('')
  const debouncedSearchTerm = useDebounce(searchTerm, 300)
  
  const { data: leads } = useLeadsQuery({
    search: debouncedSearchTerm,
    enabled: debouncedSearchTerm.length > 2
  })

  return (
    <div>
      <input
        type="text"
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        placeholder="Search leads..."
        className="w-full p-3 border border-[#D4D4D4] rounded-md"
      />
      <LeadList leads={leads} />
    </div>
  )
}
```

## 🔧 Build & Deploy Optimizations
```typescript
// ✅ Vite configuration for optimal builds
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          ui: ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
          charts: ['recharts'],
          utils: ['date-fns', 'lodash-es']
        }
      }
    },
    sourcemap: false, // Disable in production
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // Remove console logs
        drop_debugger: true
      }
    }
  },
  plugins: [
    react(),
    // Bundle analyzer
    process.env.ANALYZE && bundleAnalyzer()
  ]
})

// ✅ Service Worker for caching
// sw.js
const CACHE_NAME = 'fechtclub-v1'
const urlsToCache = [
  '/',
  '/static/css/main.css',
  '/static/js/main.js'
]

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  )
})

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        return response || fetch(event.request)
      })
  )
})
```

## 📊 Performance Metrics & Monitoring
```typescript
// ✅ Web Vitals tracking
const trackWebVitals = () => {
  if (typeof window !== 'undefined') {
    import('web-vitals').then(({ getCLS, getFID, getFCP, getLCP, getTTFB }) => {
      getCLS(console.log)
      getFID(console.log)
      getFCP(console.log)
      getLCP(console.log)
      getTTFB(console.log)
    })
  }
}

// ✅ Custom performance metrics
const usePerformanceMetrics = () => {
  useEffect(() => {
    // Measure time to interactive
    const measureTTI = () => {
      if ('PerformanceObserver' in window) {
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            if (entry.name === 'first-contentful-paint') {
              console.log(`FCP: ${entry.startTime.toFixed(2)}ms`)
            }
          })
        })
        
        observer.observe({ entryTypes: ['paint'] })
        return () => observer.disconnect()
      }
    }

    measureTTI()
  }, [])
}
```

## ✅ Performance Checklist

### Development
- [ ] Use React.memo for expensive components
- [ ] Implement useCallback and useMemo appropriately
- [ ] Avoid creating objects/functions in render
- [ ] Use lazy loading for routes and heavy components
- [ ] Implement virtual scrolling for large lists
- [ ] Optimize React Query cache settings

### Images & Assets
- [ ] Implement responsive images with srcset
- [ ] Use lazy loading for non-critical images
- [ ] Optimize image formats (WebP, AVIF)
- [ ] Implement proper image fallbacks
- [ ] Minimize bundle size with tree-shaking

### Network
- [ ] Implement proper caching strategies
- [ ] Use optimistic updates for better UX
- [ ] Implement request deduplication
- [ ] Add retry logic with exponential backoff
- [ ] Monitor and optimize API response times

### Mobile
- [ ] Optimize touch response times
- [ ] Implement pull-to-refresh efficiently
- [ ] Use intersection observer for scroll performance
- [ ] Optimize for low-end devices
- [ ] Test on various network conditions

### Monitoring
- [ ] Track Core Web Vitals
- [ ] Monitor bundle sizes
- [ ] Set up performance budgets
- [ ] Implement error monitoring
- [ ] Track long tasks and memory usage

This performance framework ensures your application remains fast and responsive across all devices and network conditions.
